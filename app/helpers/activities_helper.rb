# encoding: UTF-8

module ActivitiesHelper

  def linked_title_of(activity)
    return unless activity.entity
    return unless current_user
    return unless current_user.owns?(activity.entity) || (activity.entity.respond_to?(:user) && activity.entity.user == current_user)
    return unless (title_method = %w(title provider).detect{ |m| activity.entity.respond_to?(m) }).present?
    
    "'#{activity.entity.send(title_method)}'"
  end
  
end