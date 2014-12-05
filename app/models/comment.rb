# encoding: UTF-8

class Comment < ActiveRecord::Base
  opinio

  after_create :send_comment_mail

  def self.default_per_page
    10
  end

  # after_create :reward_commentor

  validates :commentable, :presence => true
  validates :owner,       :presence => true
  
  # def reward_commentor
  #   owner.reward_for(self.commentable, :comment)
  # end
  
  def writable?(user = ActiveRecord::AccessControl.current_user)
    return false unless user
    return false unless commentable

    user.admin? or (owner == user) or (user.owns?(commentable))
  end
  
private

  def send_comment_mail
    # do not inform user about it's own comment
    return if commentable.owner == self.owner
    
    mail = UserMailer.commentable_commented(self)
    Deferred.mail(mail)
  end

end
