# -- extend FormBuilder with a control_group method which renders
#    a default control group for Twitter Bootstrap forms. 

ActionView::Helpers::FormBuilder

class ActionView::Helpers::FormBuilder
  extend Forwardable
  delegate [:link_to, :image_for] => :@template

  # content_tag reimplementation for FormBuilder.
  #
  # It would be nice to just use @template.content_tag, but
  # Rails' HTML escaping messes up things.
  def content_tag(name, *args, &block)
    attrs = args.extract_options!
    args.push yield if block_given?

    if attrs[:data].is_a?(Hash)
      data = attrs.delete(:data)
      
      data.each do |key, value|
        attrs["data-#{key}"] = value
      end
    end
    
    unless attrs.empty?
      escaped_attrs = " " + 
        attrs.map { |k, v| "#{k}='#{CGI.escapeHTML(v.to_s)}'" }.join(" ")
    end

    "<#{name}#{escaped_attrs}>#{args.join("\n")}</#{name}>".html_safe
  end

  alias :tag :content_tag

  # Shortcut for a div block.
  def div(*args, &block)
    content_tag :div, *args, &block
  end

  DEFAULT_INPUT_FIELD_OPTIONS = {
    :text_field     => { :class => "input-xxlarge" },
    :password_field => { :class => "input-xxlarge" },
    :text_area      => { :class => "input-xxlarge" },
    :buttons        => { :class => "input-xxlarge" }
  }
  
  # Creating a control_group.
  def control_group(*args, &block)
    input_field_options = args.extract_options!
    
    name, field_type = *args
    field_type ||= :text_field
    
    raise ArgumentError, "Invalid field_type #{field_type.inspect}" unless respond_to?(field_type)
    raise ArgumentError, "Invalid attribute #{object.class.name}##{name.inspect}" unless object.respond_to?(name)
    
    if default_input_field_options = DEFAULT_INPUT_FIELD_OPTIONS[field_type]
      input_field_options = default_input_field_options.merge(input_field_options)
    end

    if field_type == :hidden_field
      hidden_field name, input_field_options
    else
      render_control_group field_type, name, input_field_options, &block
    end
  end

  def control_group_class(name)
    if object.error_message_for(name)
      "control-group error"
    else
      "control-group"
    end
  end
  
  def render_control_group_label(field_type, name, options)
    return if field_type == :check_box

    if label_text = options.delete(:label)
      content_tag :label, label_text, :class => "control-label"
    end
  end

  def render_control_group_input(field_type, name, options, &block)
    if block_given? 
      yield
    else
      options[:placeholder] ||= object.class.human_attribute_name(name)
      self.send field_type, name, options
    end
  end

  def render_control_group_controls(field_type, name, options, &block)
    if field_type == :check_box
      label_text = options.delete(:label) || object.class.human_attribute_name(name) #I18n.t("activerecord.attributes.#{object_name}.#{name}")

      controls = content_tag :label do
        render_control_group_input(field_type, name, options, &block) +
        label_text.html_safe
      end
      message = ""
    else
      controls = render_control_group_input(field_type, name, options, &block)
    end
    
    unit = if (unit_text = options.delete(:unit))
      content_tag :div, unit_text, :class => "unit"
    end
    
    div :class => "controls" do
      "#{controls}#{unit}"
    end
  end
  
  def render_control_group_message(field_type, name, options)
    message = div :class => "message hidden" do
      if object.errors.include?(name)
        "#{object.class.human_attribute_name(name)} #{object.error_message_for(name)}"
      else
        return "" if options[:hint] == false
        value = case name.to_s
          when "password" then Identity::Email::MIN_PASSWORD_LENGTH
          end
        options[:hint] || I18n.t("#{object.class.name.underscore}.form.field_hint.#{options[:name] || name}", :value => value)
      end
    end
  end
  
  def render_control_group(field_type, name, options, &block)
    div :class => control_group_class(name) do
      "#{render_control_group_label(    field_type, name, options)}\n" +
      "#{render_control_group_controls( field_type, name, options, &block)}\n" +
      "#{render_control_group_message(  field_type, name, options)}\n"
    end
  end
  
  def compliance(name, options)
    div :class => :compliance do
      object.send(name)
    end
  end

  COMPLIANCES = {
    0   => "red",
    5   => "yellow", 
    10  =>  "green"
  }  
  
  def compliance_chooser(name, options)
    current_value = object.send(name) || 5
    
    hidden_field = self.hidden_field(name, options)
    COMPLIANCES.map do |value, klass|
      div :class => "compliance_chooser #{klass}" do
        radio_button name, value, :checked => (current_value == value)
      end
    end.join("")
  end

  def agree_to_terms
    div :class => "control-group" do
      div :class => "controls" do
        I18n.t "sessions.agree_to_terms"
      end
    end
  end

  def agree_to_terms!
    html = <<-HTML
<div class='control-group'>
  <div class='controls'>
    <label>
      <input id="agree_to_terms" type="checkbox" />
      #{I18n.t "sessions.agree_to_full_terms"}
    </label>
  </div>
</div>
HTML
    html.html_safe
  end
  
  # Render form actions.
  # All forms get "Cancel", "Create" or "Cancel", "Update" actions, depending
  # on whether the current object is a new or an existing record.
  def actions(options)
    expect! options => { :cancel_url => String, :label => [ String, nil ] }

    div :class => "buttons #{DEFAULT_INPUT_FIELD_OPTIONS[:buttons][:class]}" do
      parts = []

      # 
      cancel_btn = link_to(I18n.t(:cancel), options[:cancel_url], :class => "btn")

      label = options[:label]
      label ||= object.new_record? ? I18n.t(:create) : I18n.t(:update)
      save_btn = submit(label, :class => "btn btn-primary btn-inverse btn-large")

      "#{cancel_btn} #{save_btn}"
    end
  end
  
  def error_messages(options = {})
    if options.is_a?(String)
      options = { :object => object, :scope => object_name, :message => options }
    else
      options = { :object => object, :scope => object_name, :message => nil }.update(options)
    end

    @template.partial "shared/error_messages", options
  end
  
  #
  # renders a filepicker input tag. This needs an event listener
  # installed on the input[type=filepicker] input node, which is 
  # done with JS code in filepicker.js
  def filepicker(name, options)
    slide_name = "fp_slides_#{object_name}_#{name}"       # name for slideshow node
    target_name = "#{object_name}[#{name}][]"             # name for target input nodes

    data = filepicker_data(options)                       # add filepicker_data from options
    
    data.update "fp-slides" => "##{slide_name}",          # adds name for slides node
                "fp-name" => "#{object_name}[#{name}][]"  # adds target input name

    # build HTML
    slides = tag :ul, :id => slide_name, :class => "fp-slides"
    input = tag :input, :type => :filepicker, :data => data

    "#{slides}#{input}"
  end
  
  # returns a hash of filepicker.io options to set in the filepicker's
  # input tag.
  def filepicker_data(options)
    data = options[:data] || {}
    
    services  = [ "COMPUTER", "FACEBOOK", "FLICKR", "PICASA" ]
    mimetypes = [ 'image/*' ]
    maxSize   = 1 * 1024 * 1024

    {
      "fp-button-text"  => options[:placeholder],
      "fp-button-class" => "btn",
      "fp-mimetypes"    => mimetypes.join(","),
      "fp-multiple"     => true,
      "fp-services"     => services.join(","),
      "fp-openTo"       => services.first,
      "fp-maxSize"      => maxSize
    }.update(data)
  end
end
