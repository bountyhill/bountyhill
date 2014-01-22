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
# - Identity::Address
# - Identity::Deleted
#
class Identity < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user, :on => :save
  
  after_create :create_user_if_missing
  after_create :reward_user
  
  after_destroy :soft_delete_user

  serialize :serialized, Hash
  attr_accessor   :delete_me, :accept_terms
  attr_accessible :commercial, :accept_terms
  
  #
  # returns the identities covered by OmniAuth
  def self.oauth_identities
    self.subclasses.map{ |i| i.name.split("::").last.downcase.to_sym } - [:deleted, :email, :address]
  end

  def self.provider(provider)
    expect! provider => Symbol
    
    self.subclasses.detect{ |i| i.name.split("::").last.downcase.to_sym == provider}
  end
  
  def self.find_user(attributes={})
    expect! attributes => Hash
    
    if (email = attributes[:email]) && (identity = where(:email => email).first) 
      identity.user
    end
  end

  def provider
    self.class.name.split("::").last.downcase.to_sym
  end
  
  def solitary?
    user.identities == [self]
  end
  
  # 
  # checks if the identity is ready to be further processed
  # e.g. all preconditions are fullfilled to start the oauth dance
  def processable?
    return true if self.user && !self.user.new_record?

    # clean error on accept_terms
    self.errors.delete(:accept_terms)
    
    # check if terms of use have been accepted
    self.errors.add(:accept_terms, :accepted) if self.accept_terms.to_i.zero?
    
    self.errors.blank?
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
