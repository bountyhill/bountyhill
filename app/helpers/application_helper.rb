module ApplicationHelper
  # returns "active" if the nav_item belongs to the current controller.
  def navigation_item_class_for(nav_item)
    if controller.class.name.gsub("Controller","").downcase == nav_item
      "active"
    end
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

  def render_imgio_tag(original_image_url, options)
    width, height = options.values_at(:width, :height)
    options[:width], options[:height] = "100%", nil
    url = "#{IMGIO}/jpg/50/fill/#{width}x#{height}/#{original_image_url}"
    
    image_tag url, options
  end
  
  def render_image_for(size, quest, options)
    expect! size => String

    options[:title] ||= quest.title
    
    width, height = options.values_at :width, :height
    
    if IMGIO && width && height && (url = quest.original_image_url)
      # We are using imgio and width and height are properly requested?
      render_imgio_tag(url, options)
    elsif image_data = quest.image[size]
      # The quest.image hash should have a entry with key \a size, which
      # is a Hash holding url, witdh, height, etc.
      url, options[:width], options[:height] = image_data.values_at("url", "width", "height")
      image_tag url, options
    else
      # If not we are just using a default image.
      image_tag "/images/dummy.png", options
    end
  end
  
  def show_company_footer?
    request.path == "/"
  end

  def partial(partial, *args)
    locals = args.extract_options!
    expect! partial => String, args.length => [0,1]
    
    options = {}
    options[:partial] = partial
    options[:object] = args.first if args.first 
    options[:locals] = locals if locals.present?

    render options
  end
end
