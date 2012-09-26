# encoding: utf-8

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

  # -- Finding --------------------------------------------------------
  
  def self.by_handle(handle)
    expect! handle => String
    
    identity = case handle
    when /^.+@(.*)/ then  Identity::Email.find_by_email(handle)
    when /^@(.*)/   then  Identity::Twitter.find_by_email($1)
    else                  Identity::Twitter.find_by_email(handle)
    end

    identity.user if identity
  end

  def self.by_handle!(handle)
    by_handle(handle) ||
      raise(ActiveRecord::RecordNotFound, "Couldn't find User with handle: #{handle.inspect}") 
  end
  
  # -- Identities -----------------------------------------------------

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
    if identity = self.identity(:email)
      name = identity.name
    end
    
    if name.blank? && identity = self.identity(:twitter)
      name = identity.name
    end

    if name.blank? && identity = self.identity(:email)
      name = identity.email
    end
    
    name
  end

  # return the user's email
  def email
    return unless identity = self.identity(:email)
    identity.email
  end

  # returns the email if it is confirmed
  def confirmed_email
    return unless identity = self.identity(:confirmed)
    identity.email
  end

  # confirm the email address
  def confirm_email!(flag = true)
    self.identity(:email).confirm!(flag)
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

  # -- offers ---------------------------------------------------------
  
  # returns true if the user has any current offers
  def current_offers?
    quests.active.first || offers.first
  end

  # -- special System users -------------------------------------------

  # sign over ownerships.
  #
  # Examples:
  #
  #   User.transfer! model1 => current_user, model2 => current_user
  #
  # The objects to sign over must all be either owned by the receiving 
  # user, or be owned by User.draft.
  #
  # <b>The receiving user must be ActiveRecord.current_user.</b> This is
  # probably strange and turns that parameter into somthing bogus, but 
  # allows for a better reading code:
  #   User.transfer! rec => current_user
  # instead of, say, 
  #   current_user.transfer! rec
  #   User.transfer! rec
  #
  def self.transfer!(transfers)
    expect! transfers => Hash
    
    transfers = transfers.map do |object, target_user|
      expect! target_user => ActiveRecord.current_user
      expect! object => ActiveRecord::Base

      next if object.owner == target_user
      raise ArgumentError, "#{object.uid} is not owned by draft" unless object.owner.draft?

      object
    end.compact
    
    transaction do
      target_user = ActiveRecord.current_user

      ActiveRecord.as(User.admin) do
        transfers.each do |object|
          object.owner = target_user
          object.save!
        end
      end
    end
  end

  def inspect
    parts = []

    if identity = self.identity(:twitter)
      parts << "@#{identity.email}"
    end

    if identity = self.identity(:confirmed)
      parts << "#{identity.email} (✓)"
    elsif identity = self.identity(:email)
      parts << identity.email
    end
    
    "#<User id: #{id} [#{parts.join(", ")}]>"
  end
  
  # -- user information -----------------------------------------------
  serialize :serialized, Hash
  serialized_attr :first_name, :last_name, :address1, :address2, :city, :zipcode, :country
  attr_accessible :first_name, :last_name, :address1, :address2, :city, :zipcode, :country

  attr :delete_me, true
  attr_accessible :delete_me, :deleted_at

  attr :description, true
  attr_accessible :description
end
