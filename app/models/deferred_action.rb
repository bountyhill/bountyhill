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
  include ActiveRecord::RandomID
  before_create :set_secret

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

  validate :validate_action

  def self.valid_actions
    DeferredActionsController.instance_methods(false).
      map { |sym| sym.to_s.gsub!(/^perform_/, "") }.compact
  end
  
  def validate_action
    return if action.in? self.class.valid_actions
    errors.add :action, "Action #{action.inspect} is not valid; valid actions: #{self.class.valid_actions.inspect}"
  end
  
  def performable?
    !performed_at? && !expired? && valid?
  end
  
  # Perform the DeferredAction. 
  #
  # On an error this raises an exception, which message can be
  # used to show a error message to the user.
  def perform!(options = Hash)
    raise("This link is no longer valid.") unless performable?

    expect! options => { :on => DeferredActionsController }

    ActiveRecord.as(actor) do
      options[:on].send("perform_#{action}", *args)
      update_attributes! :performed_at => Time.now
    end
  rescue
    update_attributes! :performed_at => Time.now, :error => $!.to_s
    raise
  end
  
  # Note: This method is not super secure. It gives roughly ~65..70 bits of security.
  def set_secret
    expect! self.id => Integer # id should be set already
    
    self.secret = Digest::SHA1.hexdigest("id/#{SecureRandom.random_number(0x80000000)}/#{Time.now}")
  end

  # -- DeferredAction URLs --------------------------------------------
  
  def self.default_url_options=(default_url_options)
    @@default_url_options = default_url_options
  end

  @@default_url_options = {
    host: "bountyhill.local",
    protocol: "http"
  }
  
  def url
    protocol, host = @@default_url_options.values_at :protocol, :host
    CGI.build_url "#{protocol}://#{host}/act?#{secret}", :action => action
  end
end
