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

  def h4(*content, &block)
    _content_tag(:h4, *content, &block)
  end
  
  def div(*content, &block)
    _content_tag(:div, *content, &block)
  end

  def span(*content, &block)
    _content_tag(:span, *content, &block)
  end
  
  def strong(*content, &block)
    _content_tag(:strong, *content, &block)
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
  
  def small(*content, &block)
    _content_tag(:small, *content, &block)
  end
  
  def xmp(s)
    content_tag :xmp, s
  end

  def debug(s)
    content_tag :pre, s
  end

  def markdown(name, options = {})
    html = render :partial => name
    div html.html_safe, options
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

  def render_restriction(model, what)
    expect! model => ActiveRecord::Base, what => [:location, :expires_at, :created_at, :compliance]
    value = model.send(what)
    return if value.blank?
    
    case what
    when :location
      icon = image_tag '/images/icon/location.png', :class => 'locality'
      span = self.span value, :class => "locality"
    when :expires_at
      icon = image_tag '/images/icon/calendar.png', :class => 'temporality'
      span = self.span t('restriction.temporality', :count => (value.to_date - Date.today).to_i), :class => "temporality"
    when :created_at
      icon = image_tag '/images/icon/calendar.png', :class => 'temporality'
      span = self.span t('restriction.created_at', :time => time_ago_in_words(value)), :class => "temporality"
      span = self.span t('restriction.created_at', :time => value.to_s), :class => "temporality"
    when :compliance
      icon = image_tag '/images/icon/location.png', :class => 'compliance'
      span = self.span I18n.t("restriction.compliance", :compliance => value), :class => "compliance"
    end
    
    # div icon, span, :class => "restriction"
    div span, :class => "restriction"
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
  
  HEADER_ICONS = {
    :bubble   => "d",
    :rect     => "c",
    :twitter  => "t",
    :start    => "V",
    :stop     => "W"
  }

  def interaction_buttons(*buttons)
    div :class => "socialmedia" do
      buttons.compact.join.html_safe
    end
  end
  
  def header_button(icon, url, options={})
    expect! icon  => HEADER_ICONS.keys
    expect! url   => String
    
    link_to(HEADER_ICONS[icon], url, options.merge(:class => "social-item #{icon}"))
  end

  def header_action(icon, url, options={})
    title = options.delete(:title).to_s
    text = options.delete(:text).to_s
    
    link_to url, options.merge(:class => "header-action") do
      div(HEADER_ICONS[icon] || "", :class => "icon") + 
      p("#{strong title} #{text}".html_safe)
    end
  end

  def header_ribbon(*elements)
    options   = elements.extract_options!
    span_size = 12 / elements.size
    
    div(:class => "horizontal-ribbon") do
      [
        div(:class => "row-fluid bg-gray") do
          div(:class => "span12") do
            elements.map do |element|
              div element, :class => "span#{span_size}"
            end.join.html_safe
          end
        end,
        div(:class => "corner left"),
        div(:class => "corner right")
      ].join.html_safe
    end
  end
  
  def render_form(span_left=2, span_right=2, &block)
    span = 12 - span_left - span_right

    [
      div("&nbsp;", :class => "span#{span_left}"),
      div(:class => "span#{span}") do
        div(:class => "inner form-container") do
          [
            div(:class => "tape top left"),
            div(:class => "tape top right"),
            block_given? ? capture(&block) : "",
            div(:class => "tape bottom left"),
            div(:class => "tape bottom right")
          ].join.html_safe
        end
      end,
      div("&nbsp;", :class => "span#{span_right}")
    ].join.html_safe + javascript_tag("$(document).ready(function() { $('form').setFocus(); });")
  end

  def link_to_follow_twitter_account(options = {}, &block)
    expect! options => { :account => [String, nil] }
    account = options[:account] || Bountybase.config.twitter_app["user"]
    
    link_to "http://twitter.com/#{account}", :target => :blank do
      yield block if block_given?
    end
  end
  
  # This method returns true, 
  # - if the current_user was referenced in the URL as the owner, 
  # - or if a user was referenced and it's the current user
  # - or if a single quest or offer was referenced and belongs the user 
  def personal_page?
    return false unless current_user
    return true if params[:owner_id].to_i == current_user.id
    return true if @user  && current_user == @user
    return true if @quest && current_user == @quest.owner
    return true if @offer && current_user == @offer.owner
  
    false
  end

  def filepicker_tags
    apikey = Bountybase.config.filepicker["apikey"]
    html = <<-HTML
      <script src="https://api.filepicker.io/v1/filepicker.js"></script>
      <script type="text/javascript">filepicker.setKey(#{apikey.to_json});</script>
    HTML
    
    html.html_safe
  end
  
  def random_even_unenven
    (rand(99) % 2).zero? ? "even" : "uneven"
  end
end
