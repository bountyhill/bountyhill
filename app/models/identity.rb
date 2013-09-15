# encoding: UTF-8

# stores a user's identity.
#
# An identity is needed to
# 
# - interact with a specific identity provider (e.g. an Identity::Twitter
#   object contains all information needed to post to twitter on a
#   user's behalf), and  
# - to verify a certain level of user identification (e.g. to post
#   or to reply to a quest a user must (probably) have an email
#   identity.
#
# There are specific subclasses:
#
# - Identity::Twitter
# - Identity::Facebook
# - Identity::Email
# - Identity::Deleted
#
class Identity < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user, :on => :save
  
  after_create :create_user_if_missing
  after_create :reward_user
  
  after_destroy :soft_delete_user

  serialize :serialized, Hash
  attr_accessor   :delete_me

  def self.social_identities
    self.subclasses.map{ |i| i.name.split("::").last.downcase.to_sym } - [:deleted, :email]
  end

  def self.provider(provider)
    expect! provider => Symbol
    self.subclasses.detect{ |i| i.name.split("::").last.downcase.to_sym == provider}
  end

  #
  # this implies that the identity does not responds to the methods 'avatar' and 'name'
  def identity_provider?
    false
  end
  
  def solitary?
    user.identities == [self]
  end
  
  protected
  
  def soft_delete_user
    return unless user && solitary?
    
    user.soft_delete!
  end

  def create_user_if_missing
    return if self.user
  
    user = User.new 
    user.identities << self
    user.save!
  end
  
  def reward_user
    user.reward_for(self)
  end
  
end
