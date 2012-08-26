module ApplicationHelper

  # Returns the full title on a per-page basis
  def page_title(title)
    main_title = "bountyhill"
    return main_title if title.blank?
    "#{main_title} | #{title}"
  end

  def error_message_for(object, attribue)
    return if (error_messages = object.errors[attribue]).blank?
    content_tag(:span, error_messages.first, :class => "help-inline")
  end

  def error_class_for(object, attribue)
    return "error" unless object.errors[attribue].size.zero?
  end

end
