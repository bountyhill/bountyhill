module ButtonHelper

  def button_group(buttons)
    expect! buttons => Array
    
    div :class => "btn-group" do
      buttons.join.html_safe
    end
  end
  
  def modal_link_to(name, options, html_options={})
    link_to name, options, html_options.merge(:"data-toggle" => "modal", :"data-target" => "#myModal")
  end
  
  def modal_awesome_button(name, url, options={}, &block)
    expect! name => Symbol
    expect! url => String
    
    awesome_button(name, url, { :html => { :"data-toggle" => "modal", :"data-target" => "#myModal" }.merge(options) }, &block)
  end
  
  def awesome_icon name, *args, &block
    hash = the_awesome_icon name, *args, &block
    options = hash[:options]
    content = hash[:content].html_safe
    content = ' ' + content unless content.empty? || content[0] == '<'
    content_tag(:i, nil, options) + content
  end

  def awesome_button(name, href='#', options={}, &block)
    expect! name => Symbol
    expect! href => String

    size = (options[:size] ||= :small)
    html = (options.delete(:html) || {})
    text = options.delete(:text)
    
    css_class = "btn btn-link"
    css_class << " btn-#{size}" if size
    
    content_tag :a, html.merge(:class => css_class, :href => href) do
      awesome_icon name, options, &block
    end
  end

  protected

  def the_awesome_icon name, *args, &block
    options = args.extract_options!
    size = options.delete(:size) if options
    content = args.first unless args.blank?
    content ||= capture(&block) if block_given?
    content ||= ''

    name = name.to_s.dasherize
    name.gsub!(/^icon-/, '')

    clazz = "icon-#{name}"
    clazz << " icon-#{size}" if size.to_s == 'large'
    clazz << " " << options.delete(:class) if options[:class]

    options.merge!(:class => clazz)

    {:options => options, :content => content}
  end
end