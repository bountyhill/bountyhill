module IconHelper
  
  def icon_for(identifier)
    expect! identifier => [String, Symbol]
    
    case identifier.to_sym
      when :commercial  then :group
      when :private     then :user
      when :address     then :home
      when :email       then :envelope_alt
      when :facebook    then :facebook_sign
      when :twitter     then :twitter
      when :google      then :google_plus_sign
      when :linkedin    then :linkedin_sign
      else raise "Cannot provide icon for: #{identifier.inspect}!"
    end
  end

  def awesome_icon(name, *args, &block)
    hash = the_awesome_icon name, *args, &block
    options = hash[:options]
    content = hash[:content].html_safe
    content = ' ' + content unless content.empty? || content[0] == '<'
    content_tag(:i, nil, options) + content
  end
  
protected

  def the_awesome_icon(name, *args, &block)
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