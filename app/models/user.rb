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

  private

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
  
  public

  #
  # Each user has at least a single identity, but can probably have more
  # than one. Each identity should be from a different identity provider
  # and should therefore be from a different class - but this is enforced
  # nowhere in the code.
  has_many :identities
  validates_presence_of :identities

  has_many :quests

  # Offers that this user has submitted.
  # has_many :submitted_hints, :class_name => "Hint"
  
  # Match identity symbol to class.
  IDENTITY_MODES = {
    :twitter => Identity::Twitter,
    :email   => Identity::Email
  }
  
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
  def identity(mode)
    expect! mode => IDENTITY_MODES.keys

    identities.detect do |identity|
      identity.is_a?(IDENTITY_MODES[mode])
    end
  end
  
  alias :identity? :identity
  
  # Exception class for User#identity!
  class MissingIdentity < RuntimeError; end
  
  # returns a user's identity or raises an exception. See: User#identity
  # 
  # Example:
  #
  #   user.identity!(:twitter)
  #   => might raise a User::MissingIdentity error
  def identity!(mode)
    identity(mode) || raise(MissingIdentity, "No #{mode} identity")
  end

  # -- automatic pseudo "attributes" : these methods try to return
  # a sensible attribute value from one of the user's identities.

  # return the user's name
  def name
    identity_for_name = identity(:email) || identity(:twitter)
    identity_for_name.name
  end

  # return the user's email
  def email
    if identity = self.identity(:email)
      identity.email
    end
  end

  # returns a user's avatar URL
  def avatar(options = {})
    expect! options => { :default => [ String, nil ]}

    url = (identity = self.identity(:twitter)) && identity.avatar(options)
    url ||= (identity = self.identity(:email)) && identity.avatar(options)
    url || options[:default]
  end
end
