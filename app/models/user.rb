# encoding: UTF-8

require_dependency "identity"
require_dependency "identity/twitter"
require_dependency "identity/facebook"
require_dependency "identity/email"

# The User model.
#
# A User model reflects a single user. This is separate from a user identity;
# which collects information about a user's account from an identity provider
# (say Twitter or Facebook).
class User < ActiveRecord::Base
  include ActiveRecord::RandomID

  before_save   :create_remember_token
  before_create :init_avatar_image 
  
  with_metrics! "accounts"

  serialize :badges, Array

  # -- DELETION ---------------------------------------------------

  # reason for withdrawle
  DELETION = %w(bad_service bothering_users other_reason)

  attr_accessor   :delete_me
  serialized_attr :deletion, :deletion_reason
  attr_accessible :deletion, :deletion_reason, :delete_me


  private

  # The create_remember_token method will be called on each save, 
  # because a User object could be created from bountybase, in 
  # which case the remember_token does not exist.
  #
  # Only after the first "real login" the remember_token must exist,
  # and it must not change during the User object's lifetime.
  def create_remember_token
    unless self.remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end
  end
  
  def init_avatar_image
    return if image.present?
    
    # try to fetch avatar from identity providers
    image = if (identity = identities.detect{ |identity| identity.identity_provider? && !identity.avatar.blank? })
        identity.avatar(options)
      end
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
  # Activities performed by the user
  has_many :activities, :dependent => :destroy

  #
  # Quests submitted by the user
  has_many :quests, :foreign_key => "owner_id", :dependent => :destroy
  
  # TODO: REMOVE ME! The forwards infrastructure duplicates shared_quests,
  # but with added functionality.
  has_and_belongs_to_many :shared_quests, :class_name => "Quest", 
    :join_table => :users_quests_sharings,
    :uniq => true
  
  #
  # 
  has_many  :forwards, :foreign_key => :sender_id
  has_many  :forwarded_quests, :through => :forwards, :source => :quest
  
  #
  # Offers submitted by the user
  has_many :offers, :foreign_key => "owner_id", :dependent => :destroy

  #
  # The user (monetary) account
  has_one :account, :foreign_key => "owner_id", :dependent => :destroy
  
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
    expect! mode => [:any, :email, :confirmed, :twitter, :facebook, :deleted]
    
    case mode
    when :email     then identities.detect { |i|  i.is_a?(Identity::Email) }
    when :confirmed then identities.detect { |i|  i.is_a?(Identity::Email) && i.confirmed? }
    when :twitter   then identities.detect { |i|  i.is_a?(Identity::Twitter) }
    when :facebook  then identities.detect { |i|  i.is_a?(Identity::Facebook) }
    when :deleted   then identities.detect { |i|  i.is_a?(Identity::Deleted) }
    else                 identities.detect { |i| !i.is_a?(Identity::Deleted) }
    end
  end

  public
  
  def identity?(*modi)
    identity(*modi).present?
  end
  
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

  #
  # helper method to decide if on object belongs to the use
  def owns?(object)
    self == object.owner
  end

  # -- automatic pseudo "attributes" : these methods try to return
  # a sensible attribute value from one of the user's identities.

  attr_accessible :commercial
  
  # return wether the user is commercially using bountyhill 
  def commercial
    identities.any?(&:commercial)
  end
  alias_method :commercial?, :commercial

  def commercial=(value)
    Identity.update_all({:commercial => value}, { :id => identity_ids} )
  end

  # return the user's name
  def name
    unless (name = "#{first_name} #{last_name}").blank?
      return name
    end
    
    if (email = find_identity(:email))
      return email.name unless email.name.blank?
    end
    
    if (identity = identities.detect { |identity| identity.identity_provider? && !identity.name.blank? })
      identity.name
    end
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

  # return the user's twitter identifier
  def identifier
    if identity = self.identity(:twitter)
      identity.identifier
    end
  end

  # return the user's twitter handle
  def twitter_handle
    if twitter = self.identity(:twitter)
      twitter.handle
    end
  end
  alias_method :twitter, :twitter_handle
  
  # return the user's facebook nickname
  def facebook_nickname
    if identity = self.identity(:facebook)
      identity.nickname
    end
  end
  alias_method :facebook, :facebook_nickname

  #
  # return's the user's avatar image if the user has uploaded one, or 
  # if one of it's identities provides one, or
  # the Gravatar URL from http://gravatar.com/ for the given user.
  def avatar(options={})
    expect! options => Hash
    
    if (avatar = self.image).present?
      
      # init width and height params; https://developers.inkfilepicker.com/docs/web/#convert
      width, height = options.values_at(:width, :height)
      if width && height
        expect! width => Fixnum, height => Fixnum
        avatar += "/convert?w=#{width}&h=#{height}&fit=max"
      end
    end
    
    # try to fetch avatar from Gravatar
    # if no avatar image is given
    avatar ||= Gravatar.url(email, options)
    avatar
  end
  
  def points
    activities.sum(&:points)
  end
  
  # represents stars
  def score
    points.to_s.size
  end
  
  def url
    Bountyhill::Application.url_for "/users/#{self.id}"
  end
  
  def reward_for(object, action = :create)
    Activity.log(self, action, object)
  end
  
  # -- special System users -------------------------------------------

  module SystemUsers
    # The admin user. In production this is the @bountyhill account.
    def admin
      system_users["admin"]
    end

    # return an draft user.
    def draft
      system_users["draft"]
    end
    
    # The hermes user is used to send out messages via the @bountyhermes account.
    def hermes
      system_users["hermes"]
    end

    private

    def system_users
      @system_users ||= Hash.new do |hash, key|
        hash[key] = find_or_create_system_user key
      end
    end

    TWITTER_HANDLES = {
      "admin"   => Bountybase.config.twitter_app,
      "hermes"  => Bountybase.config.twitter_notifications,
    }
    EMAIL_HANDLES = {
      "draft" => Bountybase.config.email_draft
    }
    
    def find_or_create_system_user(key)
      expect! key => (TWITTER_HANDLES.keys + EMAIL_HANDLES.keys)

      identity = 
        if (config = TWITTER_HANDLES[key])
          Identity::Twitter.find_by_identifier(config["identifier"]) || Identity::Twitter.create!(
              :name             => key,
              :identifier       => config["identifier"],
              :consumer_key     => config["consumer_key"],
              :consumer_secret  => config["consumer_secret"],
              :info             => { :nickname => config["user"] },
              :credentials      => { :token  => config["oauth_token"], :secret => config["oauth_secret"] })
        elsif (config = EMAIL_HANDLES[key])
          Identity::Email.find_by_email(config["email"]) || Identity::Email.create!(
            :name                   => key,
            :email                  => config["email"],
            :password               => config["password"],
            :password_confirmation  => config["password_confirmation"])
        else
          raise ArgumentError, "Cannot find or create system user: #{key}!"
        end
      
      # return user
      identity.user
    end
  end
  extend SystemUsers
  
  def admin?
    (self == User.admin) || Bountybase.config.admins.include?(identifier)
  end

  def draft?
    self == User.draft
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

      next if target_user.owns?(object)
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

    if twitter = identity(:twitter)
      parts << "t:#{twitter.handle}"
    end

    if facebook = identity(:facebook)
      parts << "f:#{facebook.nickname}"
    end

    if confirmed = identity(:confirmed)
      parts << "@:#{confirmed.email} (✓)"
    elsif email = self.identity(:email)
      parts << "@:#{email.email} (-)"
    end
    
    if deleted = identity(:deleted)
      parts << "---deleted---"
    end
    
    "#<User id: #{id} [#{parts.join(", ")}]>"
  end
  
  # -- user information -----------------------------------------------
  serialize :serialized, Hash
  serialized_attr :first_name, :last_name, :company, :address1, :address2, :city, :zipcode, :country, :phone, :description, :delete_reason
  attr_accessible :first_name, :last_name, :company, :address1, :address2, :city, :zipcode, :country, :phone, :description, :delete_reason
  
  # user could have provided his profile description excplicitly
  # or we try to take one from his identities
  def description
    return self.serialized[:description] unless self.serialized[:description].blank?
    
    if (identity = self.identities.detect{ |identity| identity.respond_to?(:description) && identity.description.present? })
      identity.description
    end
  end
  
  def address
    [:company, :address1, :address2, :city, :zipcode, :country].map{ |col| self.send(col) }.compact
  end

  serialized_attr :image
  attr_accessible :image, :images
  
  validates_format_of :image, :with => URI.regexp(['http', 'https']), :allow_nil => true

  # even though we support a single image attribute, we still use 
  # pluralized attributes to access it, because some parts of the 
  # filepicker form helpers expect it that way.
  def images(size = {})
    expect! size => Hash
    [avatar(size)].compact
  end

  def images=(images=[])
    self.image = images.present? ? images.flatten.first : nil
  end

  # -- deletion -------------------------------------------------------
  #
  # we dont let a user delete her account; instead we "hide" it. This
  # way we can still access her quests, offers, and bounties.
  def soft_delete!
    User.transaction do
      # set its deleted_at timestamp
      self.deleted_at = Time.now
      save!
      
      # set the visibility of all offers and quests to deleted
      ActiveRecord::AccessControl.as(User.admin) do
        Quest.update_all({ :visibility => "deleted" }, :owner_id => self)
        # TODO: Offer.update_all({ :visibility => "deleted" }, :owner_id => self)
      end

      # remove users social identities 
      [:twitter, :facebook].each do |identity_name|
        if (_identity = identity(identity_name))
          _identity.destroy
        end
      end
      
      # adjust the email identity so, that the email address is kept for 
      # future references and that the user might re-signup with same email
      # again.
      if (email = identity(:email))
        Identity.update_all({:type => "Identity::Deleted"}, :id => email)
      end
    end
  end
  
end
