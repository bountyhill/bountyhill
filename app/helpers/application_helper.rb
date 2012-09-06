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

  def xmp(s)
    content_tag :xmp, s
  end

  def markdown(name)
    html = render :partial => name
    html.html_safe
  end

  def image_for(quest, size = "thumbnail")
    expect! size.to_s => [ "thumbnail", "fullsize", "original" ]

    hash = quest.image[size.to_s] || {}

    url = hash["url"] #.gsub(/^(http|https):/, "")

    image_tag url, :title => quest.title, :width => hash["width"], :height => hash["height"]
  end
end
