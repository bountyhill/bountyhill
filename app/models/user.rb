require_dependency "identity"
require_dependency "identity/twitter"
require_dependency "identity/email"

# The User model.
#
# A User model reflects a single user. This is separate from a user identity;
# which collects information about a user's account from an identity provider
# (say Twitter or Facebook).
class User < ActiveRecord::Base
  include ActiveRecord::RandomID

  before_create :create_remember_token

  with_metrics! "accounts"

  private

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
  
  public
  
  # -- Associations ---------------------------------------------------

  #
  # Each user has at least a single identity, but can probably have more
  # than one. Each identity should be from a different identity provider
  # and should therefore be from a different class - but this is enforced
  # nowhere in the code.
  has_many :identities, :dependent => :destroy
  validates_presence_of :identities

  #
  # Quests submitted by the user
  has_many :quests, :foreign_key => "owner_id", :dependent => :destroy

  #
  # Offers submitted by the user
  has_many :offers, :foreign_key => "owner_id", :dependent => :destroy
  
  # returns a user's identity in a specific mode, which is needed to
  # 
  # - interact with a specific identity provider (e.g. a user's twitter
  #   identity contains all information needed to post to twitter on the
  #   user's behalf), and  
  # - to verify a certain level of user identification (e.g. to post
  #   or to reply to a quest a user must (probably) have an email
  #   identity.
  #
  # Example:
  #
  #   user.identity(:twitter)
  #   => an Identity::Twitter object or nil
  def identity(*modi)
    i = nil
    modi.detect do |mode|
      i = find_identity(mode)
    end
    i
  end
  
  private
  
  def find_identity(mode)
    expect! mode => [ :email, :twitter, :confirmed, :any ]
    
    case mode
    when :email     then identities.detect { |i| i.is_a?(Identity::Email) }
    when :twitter   then identities.detect { |i| i.is_a?(Identity::Twitter) }
    when :confirmed then identities.detect { |i| i.is_a?(Identity::Email) && i.confirmed? }
    else            identities.first
    end
  end

  public
  
  alias :identity? :identity
  
  # Exception class for User#identity!
  class MissingIdentity < RuntimeError; end
  
  # returns a user's identity or raises an exception. See: User#identity
  # 
  # Example:
  #
  #   user.identity!(:twitter)
  #   => might raise a User::MissingIdentity error
  def identity!(*modi)
    identity(*modi) || raise(MissingIdentity, "No identity for #{modi.join(", ")}")
  end

  # -- automatic pseudo "attributes" : these methods try to return
  # a sensible attribute value from one of the user's identities.

  # return the user's name
  def name
    return unless identity = self.identity(:twitter, :email)
    identity.name
  end

  # return the user's email
  def email
    return unless identity = self.identity(:email)
    identity.email
  end

  def confirmed_email
    return unless identity = self.identity(:confirmed)
    identity.email
  end

  def confirmed_email?
    confirmed_email != nil
  end

  def confirm_email!
    self.identity(:email).confirm!
  end

  # return the user's twitter handle
  def twitter_handle
    if identity = self.identity(:twitter)
      "@" + identity.screen_name
    end
  end

  # returns a user's avatar URL
  def avatar(options = {})
    expect! options => { :default => [ String, nil ]}

    if identity = self.identity(:email, :twitter)
      avatar = identity.avatar(options)
    end
    
    avatar || options[:default]
  end
  
  # -- special System users -------------------------------------------

  module SystemUsers
    # return an admin user. This is the @bountyhill account.
    def admin
      system_users["admin"]
    end

    # return an draft user. This is the @bountyhill_draft account.
    def draft
      system_users["draft"]
    end

    private

    def system_users
      @system_users ||= Hash.new do |hash, key|
        hash[key] = begin
          identity = Identity::Twitter.find_by_email("bountyhill_#{key}") ||
            Identity::Twitter.create!(:email => "bountyhill_#{key}", :name => key)
          identity.user
        end
      end
    end
  end
  extend SystemUsers
  
  def admin?
    self == User.admin ||
    Bountybase.config.admins.include?(twitter_handle)
  end

  def draft?
    self == User.draft
  end

  # sign over the objects described in the transfers array.
  # The transfers array can either contain ActiveRecord::Base objects
  # or Strings a la "Quest:12".
  #
  # returns true on success or false on fail (e.g. at least one of the 
  # objects could not be transferred).
  def transfer!(transfers)
    expect! transfers => Array
  
    objects = transfers.map do |obj|
      expect! obj => [ ActiveRecord::Base, /^(Quest):.*/ ]
      next obj if obj.is_a?(ActiveRecord::Base)

      class_name, id = *obj.split(":")
      case class_name
      when "Quest" then Quest.find_by_id(id)
      end
    end.compact

    success = true
    
    ActiveRecord.as(User.admin) do
      objects.each do |object|
        object.owner = self
        if !object.save
          success = false 
        end
      end
    end
    
    success
  end
end
