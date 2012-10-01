# The DeferredAction class is a way to store an action in a safe way
# and to have the user initiate it at a later moment, via a link or
# similar.
#
# Columns and their meaning:
#
# - +secret+: A secret hash; this will be the payload of a link:
# - +actor_id+: The user id of the user to perform an action.
# - +action+: The action to perform: This must be a public method
#   in the DeferredAction::Performer module.
# - +args+: The arguments, as a serialized array.
# - +redirection+: when set, this is where the DeferredActionsController
#   should redirect after performing the action.
# - +performed_at+: timestamp of when performing a DeferredAction
# - +expires_at+: timestamp of when the DeferredAction expires.
# - +error+: error message when failed?
#
class DeferredAction < ActiveRecord::Base
  serialize :args, Array

  # Checks whether the DeferredAction expired.
  def expired?
    return false if performed_at?     # If it was performed then it didn't expire.
    return false if expires_at.nil?   # If no expiration was set it didn't expire.

    expires_at < Time.now
  end
  
  def performed?
    performed_at?
  end
  
  belongs_to :actor, :class_name => "User"
  validates_presence_of :actor
  
  # -- expiration -----------------------------------------------------
  
  # All DeferredActions expire one day after creation, unless
  # explicitely stated otherwise.

  before_create :set_expiration
  
  def set_expiration
    self.expires_at = Time.now + 1.day
  end

  # -- secrets --------------------------------------------------------
  
  include ActiveRecord::RandomID
  
  # All DeferredActions have a and are referenced by their secret
  # which is stored in the database. We add roughly ~36 bits of security
  # to the 31 bit of security from the random id.
  before_create :set_secret
  
  def set_secret
    expect! self.id => Integer # id should be set already
    
    self.secret = Digest::SHA1.hexdigest("#{id}/#{SecureRandom.random_number(0x80000000)}/#{Time.now}")
  end
  
  # -- validation -----------------------------------------------------
  
  # Actions must refer to one of the perform_XXX actions in 
  # DeferredActionsController.
  
  validate :validate_action

  def self.valid_actions
    DeferredActionsController.instance_methods(false).
      map { |sym| sym.to_s.gsub!(/^perform_/, "") }.compact
  end
  
  def validate_action
    return if action.in? self.class.valid_actions
    errors.add :action, "Action #{action.inspect} is not valid; valid actions: #{self.class.valid_actions.inspect}"
  end
  
  # -- Performing -----------------------------------------------------
  
  # Can the action be performed? It must be valid, not yet expired, and
  # not yet performed.
  
  def performable?
    !performed_at? && !expired? && valid?
  end
  
  # Perform the DeferredAction. This signs in as the actor in the 
  # stored in deferred action, and then perform the method on the
  # DeferredActionsController passed in.
  #
  # Sets the "performed_at" and, in case of an error, the "error"
  # attribute.
  # 
  # Example:
  #
  #   perform :on => controller_instance
  #
  def perform!(options = Hash)
    raise("This link is no longer valid.") unless performable?

    expect! options => { :on => DeferredActionsController }

    ActiveRecord.as(actor) do
      options[:on].send("perform_#{action}", *args)
      update_attributes! :performed_at => Time.now
    end
  rescue StandardError
    update_attributes! :performed_at => Time.now, :error => $!.to_s
    raise
  end
  
  # -- URLs -----------------------------------------------------------
  
  # This method returns an URL for the DeferredAction.
  def url
    Bountyhill::Application.url_for("act?#{action}-#{secret}")
  end
end
