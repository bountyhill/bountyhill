class Comment < ActiveRecord::Base
  opinio

  def self.default_per_page
    10
  end

  def writable?(user = ActiveRecord::AccessControl.current_user)
    return false unless user
    return false unless commentable

    user.admin? or (owner == user) or (commentable.owner == user)
  end
end
