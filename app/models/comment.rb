# encoding: UTF-8

class Comment < ActiveRecord::Base
  opinio

  def self.default_per_page
    10
  end

  after_create :reward_commentor

  validates :commentable, :presence => true
  validates :owner,       :presence => true
  
  def reward_commentor
    owner.reward_for(self.commentable, :comment)
  end
  
  def writable?(user = ActiveRecord::AccessControl.current_user)
    return false unless user
    return false unless commentable

    user.admin? or (owner == user) or (user.owns?(commentable))
  end
end
