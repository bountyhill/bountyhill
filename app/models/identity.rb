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
# - Identity::Email
#
class Identity < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user, :on => :save
  
  after_destroy :delete_user_if_deleted_last_identity
  
  serialize :options, Hash
  
  private
  
  def delete_user_if_deleted_last_identity
    return if user.identities.any? { |identity| identity.id != self.id }
    user.destroy
  end

  public
  
  after_create :create_user_if_missing

  def create_user_if_missing
    return if self.user
  
    user = User.new 
    user.identities << self
    user.save!
  end
end