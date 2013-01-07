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
    :text_field     => { :class => "input-xlarge" },
    :password_field => { :class => "input-xlarge" },
    :text_area      => { :class => "input-xlarge" },
    :select         => { :class => "input-xlarge" }
  }
  
  # Creating a control_group.
  def control_group(*args, &block)
    input_field_options = args.extract_options!
    
    name, field_type = *args
    field_type ||= :text_field
    
    raise ArgumentError, "Invalid field_type #{field_type.inspect}"               unless respond_to?(field_type)
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

  def render_control_group(field_type, name, options, &block)
    ctrl_grp = div(:class => control_group_class(name)) do
        "#{render_control_group_label(    field_type, name, options)}\n" +
        "#{render_control_group_controls( field_type, name, options, &block)}\n"
      end

    case field_type
    when :check_box
      content_tag :label, :class => "checkbox" do
        ctrl_grp
      end
    else
      ctrl_grp
    end
    
  end

  def render_control_group_label(field_type, name, options)
    return if field_type == :check_box

    label = options.delete(:label) || object.class.human_attribute_name(name)
    content_tag :label, label, :class => "control-label"
  end

  def render_control_group_controls(field_type, name, options, &block)
    message   = render_control_group_message(field_type, name, options)
    controls  = case field_type.to_sym
      when :check_box
        content_tag :label do
          render_control_group_input(field_type, name, options, &block) +
          (options.delete(:label) || field_hint(name, options)).html_safe
        end
      else
        render_control_group_input(field_type, name, options, &block)
      end
    
    div :class => (field_type.to_sym == :check_box ? "" : "controls") do
      if (unit_text = options.delete(:unit))
        div :class => "input-append" do
          controls + content_tag(:span, unit_text, :class => "add-on") + message
        end
      else
        controls + message
      end
    end
  end
  
  def render_control_group_message(field_type, name, options)
    return unless object.errors.include?(name)
    div :class => "help-inline" do
      "#{object.class.human_attribute_name(name)} #{object.error_message_for(name)}"
    end
  end
  
  def control_group_class(name)
    if object.error_message_for(name)
      "control-group error"
    else
      "control-group"
    end
  end

  def render_control_group_input(field_type, name, options, &block)
    if block_given? 
      yield
    else
      case field_type.to_sym
      when :select
        self.send field_type, name, options.delete(:select_options), {}, options
      when :check_box
        self.send field_type, name, options
      else
        options[:placeholder] ||= field_hint(name, options)
        self.send field_type, name, options
      end
    end
  end
  
  def field_hint(name, options)
    value = case name.to_s
      when "password" then Identity::Email::MIN_PASSWORD_LENGTH
      end
    options[:hint] || I18n.t("#{object.class.name.underscore}.form.field_hint.#{options[:name] || name}", :value => value)
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

  def note(note="KJH")
    div :class => 'control-group' do
      tag :label, note
    end
  end
  
  def agree_to_terms(options={})
    options[:id] ||= "agree_to_terms"
    content_tag :label, :class => "checkbox" do
      note <<-HTML
  <input id="#{options[:id]}" type="checkbox" />
  #{I18n.t "identity.form.terms"}
      HTML
    end
  end

  def forgot_password
    content_tag :label, :class => "checkbox" do
      note <<-HTML
  <input id="forgot_password" type="checkbox" />
  #{I18n.t("identity/email.form.field_hint.forgot_password")}
      HTML
    end
  end
  

  # Render form actions.
  # All forms get "Cancel", "Create" or "Cancel", "Update" actions, depending
  # on whether the current object is a new or an existing record.
  def actions(url, html_options={})
    expect! url => String
    expect! html_options => Hash

    div :class => "buttons" do
      label = html_options.delete(:label) || (object.new_record? ? I18n.t("button.create") : I18n.t("button.update"))
      css   = html_options.delete(:class) || "btn btn-primary btn-inverse"
      # 
      save_btn   = submit(label, :class => css)
      cancel_btn = link_to(I18n.t("button.cancel"), url, { :class => "btn" }.merge(html_options))

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
                "fp-name" => target_name                  # adds target input name

    # build slides to show existing slides, 
    # along with inline editing stuff.
    slides = @template.render_slides(object, :id => slide_name, :class => "fp-slides-edit") do |image, thumbnail|
      tag(:input, :type => :hidden, :name => target_name, :value => image) +
      @template.render_slide_image(thumbnail) +
      link_to("DEL", '#', :class => "fp-delete")
    end
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
      "fp-multiple"     => options.key?(:multiple) ? options[:multiple] : true,
      "fp-services"     => services.join(","),
      "fp-openTo"       => services.first,
      "fp-maxSize"      => maxSize
    }.update(data)
  end
end
