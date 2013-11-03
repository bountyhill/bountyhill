# encoding: UTF-8

module ApplicationHelper
  def endless_scroll_loader(type)
    expect! type => Symbol
    div :class => "loader" do
      link_to(awesome_icon(icon_for('other.load_indicator')) + "&nbsp;".html_safe + I18n.t("link.loading"),
        send("#{type}_path", params.merge(:page => (params[:page].to_i || 1)+1)),
        :class => 'endless_scroll_hook',
        :remote => true)
    end
  end
  
  def i18n_title_for(model, options={})
    I18n.t("#{model.class.name.downcase}.form.#{translation_key_for(model, options)}.title", options).html_safe
  end
  
  def i18n_legend_for(model, options={})
    I18n.t("#{model.class.name.downcase}.form.#{translation_key_for(model, options)}.legend", options).html_safe
  end
  
  def i18n_form_hint_for(model, options={})
    I18n.t("#{model.class.name.downcase}.form.#{translation_key_for(model, options)}.hint", options).html_safe
  end
  
  def translation_key_for(model, options={})
    if    (key = options.delete(:translation_key))  then key
    elsif model.readonly?                           then "show"
    elsif model.new_record?                         then "create"
    else                                                 "edit"
    end
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

  def ol(*content, &block)
    _content_tag(:ol, *content, &block)
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
  
  def dl(*content, &block)
    _content_tag(:dl, *content, &block)
  end

  def dt(*content, &block)
    _content_tag(:dt, *content, &block)
  end

  def dd(*content, &block)
    _content_tag(:dd, *content, &block)
  end
  
  def button(*content, &block)
    _content_tag(:button, *content, &block)
  end
  
  def label(*content, &block)
    _content_tag(:label, *content, &block)
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
  
  def form_for(object, options = {}, &block)
    html = options[:html] ||= {}
    if html[:class]
      html[:class] += " form-horizontal"
    else
      html[:class] = "form-horizontal"
    end
    
    super(object, options, &block)
  end
  
  def modal_dialog(title, options={}, &block)
    expect! title => String
    html = options[:html] ||= {}
    
    header = [
      button("&times;", :type => "button", :class => "close", :"data-dismiss" => "modal", :"aria-hidden" => "true"),
      h3(title, :id => "modal-headline", :class => "modal-headline")
    ].join.html_safe
    
    output = [
      div(header,           :class  => "modal-header #{html[:class]}"),
      div(capture(&block),  :id     => "modal-content")
    ].join.html_safe
    
    block_given? ? concat(output) : output
  end
  
  def modal_body(options={}, &block)
    html = options[:html] ||= {}
    html_options = html.merge(:class => "modal-body")
    
    output = div(capture(&block), html_options)
    block_given? ? concat(output) : output
  end
  
  def modal_footer(options={}, &block)
    output = div(capture(&block), :class => "modal-footer")

    block_given? ? concat(output) : output
  end
  
  ALLOWED_PARAMS_FOR = {
    :quests => [:owner_id, :category, :radius, :sort, :order],
    :offers => [:owner_id, :state, :sort, :order]
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
      span(flash_msg, :class => "message")
    end
  end
  
  def spacer(options={})
    div "", :class => "spacer #{options[:class]}", :style => options[:style]
  end
  
  def circle_link_to(label, url, options={})
    options[:class]     ||= 'circle'
    options[:id]        ||= "circle-#{label}-#{rand(100)}"
    options[:title]     ||= '&nbsp;'
    options[:placement] ||= 'left'
    
    link_to(div(label, :class => options[:class]), url,
            :id               => options[:id],
            :title            => options[:title],
            :"data-toggle"    => "tooltip",
            :"data-placement" => options[:placement]) + javascript_tag("$('##{options[:id]}').tooltip();")
  end
  
  def url_for_follow_twitter_account(options = {})
    expect! options => { :account => [String, nil] }

    account = options[:account] || Bountybase.config.twitter_app["user"]
    account = account.gsub("@", "")
    
    "http://twitter.com/#{account}"
  end

  def identity?(*args)
    current_user && current_user.identity(*args)
  end

  # This method returns true, 
  # - if the current_user was referenced in the URL as the owner, 
  # - or if a user was referenced and it's the current user
  # - or if a single quest or offer was referenced and belongs the user 
  def personal_page?
    return false unless current_user
    return true if params[:owner_id].to_i == current_user.id
    return true if @user  && current_user == @user
    return true if @quest && current_user.owns?(@quest)
    return true if @offer && current_user.owns?(@offer)
  
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
  
end

__END__

  def random_even_unenven
    (rand(99) % 2).zero? ? "even" : "uneven"
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
      days = (value.to_date - Date.today).to_i
      span = if value > Time.now
        self.span I18n.t('restriction.expires_on', :count => days), :class => "temporality"
      else
        self.span I18n.t('restriction.expired_on', :count => -days), :class => "temporality"
      end
    when :created_at
      icon = image_tag '/images/icon/calendar.png', :class => 'temporality'
      days = (value.to_date - Date.today).to_i
      span = self.span I18n.t('restriction.created_on', :count => -days), :class => "temporality"
    when :compliance
      icon = image_tag '/images/icon/location.png', :class => 'compliance'
      span = self.span I18n.t("restriction.compliance", :compliance => value), :class => "compliance"
    end
  
    # div icon, span, :class => "restriction"
    div span, :class => "restriction"
  end

  def quests(value, url = nil, link_options = {})
    word_with_count(:quests, value, url, link_options)
  end
  
  def offers(value, url = nil, link_options = {})
    word_with_count(:offers, value, url, link_options)
  end

  def points(value, url = nil, link_options = {})
    word_with_count(:points, value, url, link_options)
  end
  
  def link_to_follow_twitter_account(options = {}, &block)
    expect! options => { :account => [String, nil] }

    link_to url_for_follow_twitter_account(options), :target => :blank do
      yield block if block_given?
    end
  end

  HEADER_ICONS = {
    :bubble   => "d",
    :rect     => "c",
    :twitter  => "t",
    :start    => "V",
    :stop     => "W",
    :user     => "U",
    :delete   => "'"
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

  # fetches a word from translation, matching for the count. The keys are in words.<word>; 
  # e.g. words.offers. This method is mainly used from the word_with_count helper method below.
  def word(s, count)
    I18n.t("words.#{s}", :count => count)
  end
  
  # builds markup for words with counts.
  def word_with_count(s, count, url = nil, link_options = {})
    # word_with_count translation example: 
    #   <span><strong>%{count}</strong> %{word}</span>
    translated = I18n.t(:word_with_count, :count => count, :word => word(s, count)).html_safe
    return translated unless url
    link_to translated, url, link_options
  end
end
