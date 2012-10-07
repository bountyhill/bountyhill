module ApplicationHelper
  def i18n_title_for(model, attrs = {})
    key = if model.readonly?  then "show"
    elsif model.new_record?   then "create"
    else                           "edit"
    end
    
    I18n.t("#{model.class.name.downcase}.title.#{key}", attrs).html_safe
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
    link_to image_for(quest, options), quest, :class => zoom
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
      span = self.span t('restriction.temporality', :count => (value.to_date - Date.today).to_i), :class => "temporality"
    when :compliance
      icon = image_tag '/images/icon/location.png', :class => 'compliance'
      span = self.span I18n.t("restriction.compliance", :compliance => value), :class => "compliance"
    end
    
    div icon, span, :class => "restriction"
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
  
  ALLOWED_PARAMS_FOR = {
    :quests => [:filter, :category, :sort, :order],
    :offers => [:filter, :category, :sort, :order]
  }
  def params_for(controller)
    expect! controller => ALLOWED_PARAMS_FOR.keys
    
    ALLOWED_PARAMS_FOR[controller]
  end

  BOOTSTRAP_ALERT_CLASS = {
    :error    =>  "alert-error",
    :success  =>  "alert-success",
    :notice   =>  "alert-info",
    :info     =>  "alert-info"
  }

  def render_flash
    flash_msg = nil
    flash_key = [:error, :success, :warn, :notice, :info].detect do |key| 
      flash_msg = flash[key] 
    end
    
    return unless flash_key

    div :class => "flash alert #{BOOTSTRAP_ALERT_CLASS[flash_key]}" do
      link_to("x", "#", :class => "close", :"data-dismiss" => "alert") +
      flash_msg
    end
  end
  
  
  # returns the header ribbon in form of a button
  # this is used e.g. on top of list or detail pages
  def header_ribbon_button(button, name, url, options={})
    expect! button => Symbol
    expect! name => String
    expect! url => String
    expect! options => {}
    
    text = options[:text]
    
    icon = case button
      when :bubble  then "c"
      when :rect    then "d"
      when :twitter then "t"
      else ""
      end
    
    header_button = div :class => "header-button" do
      div(icon, :class => "icon") + 
      p("#{link_to(name, url)} #{text}".html_safe)
    end
    
    social_buttons = if options[:social]
      div :class => "socialmedia" do
        link_to("t", options[:social][:twitter].delete(:url), 
          options[:social][:twitter].merge(:class => "social-item twitter")) if options[:social][:twitter]
      end
    else ""
    end
    
    div(:class => "horizontal-ribbon") do
      [
        div(:class => "row-fluid bg-gray") do
          div(:class => "span12") do
            header_button + 
            social_buttons
          end
        end,
        div(:class => "corner left"),
        div(:class => "corner right")
      ].join.html_safe
    end
  end

  # returns the header ribbon in form of a headline
  # this is used e.g. on top of forms
  def header_ribbon_title(title)
    expect! title => String

    div(:class => "horizontal-ribbon") do
      [
        div(:class => "row-fluid bg-gray") do
          div(:class => "span12 headline inner") do
              h1 title
          end
        end,
        div(:class => "corner left"),
        div(:class => "corner right")
      ].join.html_safe
    end
  end

  
  def render_form(span=8, &block)
    side_span = (12-span) / 2
    
    div :class => "row-fluid main-space bg-solid-black" do
      [
        div("&nbsp", :class => "span#{side_span}"),
        div(:class => "span#{span}") do
          div(:class => "inner form-container bg-solid-gray-dark") do
            yield block if block_given?
          end
        end,
        div("&nbsp", :class => "span#{side_span}")
      ].join.html_safe + javascript_tag("$(document).ready(function() { $('form').setFocus(); });")
    end
  end
  
end
