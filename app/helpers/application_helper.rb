module ApplicationHelper
  def i18n_title_for(model, attrs = {})
    key = if model.readonly?  then "show"
    elsif model.new_record?   then "create"
    else                           "edit"
    end
    
    I18n.t "#{model.class.name.downcase}.title.#{key}", attrs
  end

  def _content_tag(name, *content, &block)
    options = content.extract_options!
    content << capture(&block) if block_given?
    content = content.join("\n").html_safe
    content_tag name, content, options
  end
  
  def h1(*content, &block)
    _content_tag(:h1, *content, &block)
  end

  def h2(*content, &block)
    _content_tag(:h2, *content, &block)
  end

  def h3(*content, &block)
    _content_tag(:h3, *content, &block)
  end
  
  def div(*content, &block)
    _content_tag(:div, *content, &block)
  end

  def span(*content, &block)
    _content_tag(:span, *content, &block)
  end

  def ul(*content, &block)
    _content_tag(:ul, *content, &block)
  end

  def li(*content, &block)
    _content_tag(:li, *content, &block)
  end

  def p(*content, &block)
    _content_tag(:p, *content, &block)
  end

  # returns "active" if the nav_item belongs to the current controller.
  def navigation_item_class_for(nav_item)
    if controller.class.name.gsub("Controller","").downcase == nav_item
      "active"
    end
  end
  
  def stats_path
    "https://www.stathat.com/home"
  end
  
  ADMIN_NAV_ITEMS = %w(stats)
  
  def link_to_nav_item(nav_item)
    if admin? || !ADMIN_NAV_ITEMS.include?(nav_item)
      link_to I18n.t("nav.#{nav_item}"), self.send("#{nav_item}_path")
    end
  end
  
  def error_message_for(object, attribute)
    if error_message = object.error_message_for(attribute)
      span(error_message, :class => "help-inline")
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

  def debug(s)
    content_tag :xmp, s
  end

  def markdown(name, options = {})
    html = render :partial => name
    div html.html_safe, options
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
  
  def partial(partial, *args)
    locals = args.extract_options!
    expect! partial => String, args.length => [0,1]
    
    options = {}
    options[:partial] = partial
    options[:object] = args.first if args.first 
    options[:locals] = locals if locals.present?

    render options
  end

  def image_link_to(quest, options)
    zoom = options.delete(:zoom) && "zoom"
    link_to image_for(quest, options), quest, 
      :class => zoom, "data-bitly-type" => "bitly_hover_card"
  end

  def render_restriction(model, what)
    expect! model => ActiveRecord::Base, what => [:location, :expires_at, :compliance]
    value = model.send(what)
    return if value.blank?
    
    case what
    when :location
      icon = image_tag '/images/icon/location.png', :class => 'locality'
      span = self.span value, :class => "locality"
    when :expires_at
      icon = image_tag '/images/icon/calendar.png', :class => 'temporality'
      span = self.span value.to_date, :class => "locality"
    when :compliance
      icon = image_tag '/images/icon/location.png', :class => 'compliance'
      span = self.span I18n.t("restriction.compliance", :compliance => value), :class => "locality"
    end
    
    div icon, span
  end

  def form_for(object, options = {}, &block)
    html = options[:html] ||= {}
    if html[:class]
      html[:class] += " form-horizontal"
    else
      html[:class] = "form-horizontal"
    end
    
    super(object, options, &block)
  end
end
