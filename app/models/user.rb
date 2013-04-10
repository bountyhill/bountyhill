# encoding: utf-8

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

  before_save :create_remember_token

  with_metrics! "accounts"

  serialize :badges, Array

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
    expect! mode => [ :email, :twitter, :facebook, :confirmed, :any ]
    
    case mode
    when :email     then identities.detect { |i| i.is_a?(Identity::Email) }
    when :twitter   then identities.detect { |i| i.is_a?(Identity::Twitter) }
    when :facebook  then identities.detect { |i| i.is_a?(Identity::Facebook) }
    when :confirmed then identities.detect { |i| i.is_a?(Identity::Email) && i.confirmed? }
    else            identities.first
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

  # return the user's name
  def name
    name = "#{first_name} #{last_name}"

    if name.blank? && identity = self.identity(:twitter)
      name = identity.name
    end

    if name.blank? && identity = self.identity(:facebook)
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
  alias_method :twitter, :twitter_handle
  
  # return the user's facebook nickname
  def facebook_nickname
    if identity = self.identity(:facebook)
      identity.nickname
    end
  end
  alias_method :facebook, :facebook_nickname

  #
  # return's the user's avatar image if the user has uploaded one, or if not
  # returns the Gravatar URL from http://gravatar.com/ for the given user.
  def avatar(options = {})
    if avatar = self.image
      width, height = options.values_at(:width, :height)
      if width && height
        avatar = "#{url}/convert?w=#{width}&h=#{height}"
      end
    end
    
    avatar ||= if (ident = [:twitter, :facebook].detect{ |id| self.identity(id) && self.identity(id).respond_to?(:avatar) })
        identity(ident).avatar
      end
    avatar || Gravatar.url(:size => options[:size])
  end
  
  def points
    activities.sum(&:points)
  end
  
  # represents stars
  def score
    points.to_s.size
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

      # TODO: Currently the draft user is linked to the @bountyhermes
      # twitter account. While this works, it would probably be better
      # to not use a Twitter identity for that user, as this user should
      # never act on twitter at all.
      "draft"   => Bountybase.config.twitter_notifications
    }
    
    def find_or_create_system_user(key)
      expect! key => TWITTER_HANDLES.keys

      config = TWITTER_HANDLES[key]
      twitter_handle = config["user"]
      identity = Identity::Twitter.find_by_email(config["user"]) || 
        Identity::Twitter.create!(:name => key, :email => config["user"])

      # Update attributes in the database to synchronize configuration
      # with database information. As this is done only once per
      # session, the runtime overhead is negligiable.
      identity.update_attributes! :consumer_key => config["consumer_key"],
        :consumer_secret => config["consumer_secret"],
        :oauth_token     => config["access_token"],
        :oauth_secret    => config["access_token_secret"]

      identity.user
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

    if identity = self.identity(:twitter)
      parts << "t:#{identity.screen_name}"
    end

    if identity = self.identity(:facebook)
      parts << "f:#{identity.nickname}"
    end

    if identity = self.identity(:confirmed)
      parts << "@:#{identity.email} (✓)"
    elsif identity = self.identity(:email)
      parts << identity.email
    end
    
    "#<User id: #{id} [#{parts.join(", ")}]>"
  end
  
  # -- user information -----------------------------------------------
  serialize :serialized, Hash
  serialized_attr :first_name, :last_name, :address1, :address2, :city, :zipcode, :country, :phone, :description
  attr_accessible :first_name, :last_name, :address1, :address2, :city, :zipcode, :country, :phone, :description
  
  # user could have provided his profile description excplicitly
  # or we try to take one from his identities
  def description
    self.serialized[:description] || self.identities.detect{ |identity| identity.description if identity.respond_to?(:description)}
  end
  
  def address
    [:address1, :address2, :city, :zipcode, :country].map{ |col| self.send(col) }.compact
  end

  serialized_attr :image
  attr_accessible :image, :images

  # even though we support a single image attribute, we still use 
  # pluralized attributes to access it, because some parts of the 
  # filepicker form helpers expect it that way.
  def images(size = {})
    width, height = size.values_at(:width, :height)
    urls = [ image ].compact

    if width && height
      expect! width => Fixnum, height => Fixnum

      # set width and height; see https://developers.filepicker.io/docs/web/#fpurl
      urls = urls.map { |url| "#{url}/convert?w=#{width}&h=#{height}" }
    end

    # set content disposition; see https://developers.filepicker.io/docs/web/#fpurl
    urls.map { |url| "#{url}?dl=false" }
  end

  def images=(images)
    self.image = images && images.first
  end

  # -- deletion -------------------------------------------------------

  # we dont let a user delete her account; instead we "hide" it. This
  # way we can still access her quests, offers, and bounties. 
  #
  # To "delete" a user you call
  #
  # user.soft_delete!

  def soft_delete!
    User.transaction do
      # set its deleted_at timestamp
      self.deleted_at = Time.now
      save!
      
      # set the visibility of all offers and quests to deleted
      Quest.update_all({ :visibility => "deleted" }, :id => quests)

      # remove its twitter acount to "release" the twitter handle
      if twitter = identity(:twitter)
        twitter.destroy
      end

      # remove its facebook acount  to "release" the facebook auth token
      if twitter = identity(:facebook)
        twitter.destroy
      end

      # adjust the email identity so, that the email address is kept for 
      # future references and that the user might re-signup with same email
      # again.
      Identity.update_all({:type => "Identity::Deleted"}, :id => identity(:email))
    end
  end
  
end
