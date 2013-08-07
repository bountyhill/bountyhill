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
  
  after_destroy :delete_user_if_deleted_last_identity

  serialize :serialized, Hash

  def self.of_provider(provider)
    expect! provider => String
    self.send(:subclasses).detect{|subclass| subclass.name.split("::").last.underscore == provider}
  end

  #
  # this implies that the identity does not responds to the methods 'avatar' and 'name'
  def identity_provider?
    false
  end
  
  private
  
  def delete_user_if_deleted_last_identity
    return unless user

    return if user.identities.any? { |identity| identity.id != self.id }
    user.destroy
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
