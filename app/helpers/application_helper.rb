module ApplicationHelper
  def error_message_for(object, attribute)
    if error_message = object.error_message_for(attribute)
      content_tag(:span, error_message, :class => "help-inline")
    end
  end

  def error_class_for(object, attribute)
    if object.error_message_for(attribute)
      "error"
    end
  end
end
