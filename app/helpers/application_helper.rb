module ApplicationHelper
  # returns "active" if the nav_item belongs to the current controller.
  def navigation_item_class_for(nav_item)
    controller.class.name.gsub("Controller","").downcase == nav_item ? "active" : ""
  end
  
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

  def thumbnail_for(quest, options = {})
    render_image_for "thumbnail", quest, options
  end
  
  def image_for(quest, options = {})
    render_image_for "fullsize", quest, options
  end
  
  def render_image_for(size, quest, options)
    expect! size => String
    
    width, height = options.values_at :width, :height
    if IMGIO && width && height && (url = quest.original_image_url)
      url = "#{IMGIO}/jpg/50/fill/#{width}x#{height}/#{url}"
    else
      # The quest.image hash must have a size entry, which is a Hash
      expect! quest.image => { size => Hash }
      
      image_data = quest.image[size]

      options[:width], options[:height] = image_data.values_at("width", "height")
      url = image_data["url"]
    end

    options[:title] ||= quest.title
    image_tag url, options
  end
  
  def show_company_footer?
    request.path == "/"
  end
end
