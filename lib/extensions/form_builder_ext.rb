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
    :text_area      => { :class => "input-xlarge" }
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

    label_text = options.delete(:label) || name
    content_tag :label, label_text, :class => "control-label"
  end

  def render_control_group_input(field_type, name, options, &block)
    if block_given? 
      yield
    else
      self.send field_type, name, options
    end
  end

  def render_control_group_controls(field_type, name, options, &block)
    if field_type == :check_box
      label_text = options.delete(:label) || name
      
      controls = content_tag :label do
        render_control_group_input(field_type, name, options, &block) +
        label_text.html_safe
      end
    else
      controls = render_control_group_input(field_type, name, options, &block)
    end

    div :class => "controls" do
      "#{controls}\n#{object.error_message_for(name)}"
    end
  end
  
  def render_control_group(field_type, name, options, &block)
    return if name == :check_box
    div :class => control_group_class(name) do
      "#{render_control_group_label(field_type, name, options)}\n" +
      "#{render_control_group_controls(field_type, name, options)}\n"
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
  
  def transloadit(name, options)
    parts = []
    parts.push @template.transloadit(:upload)

    unless object.send(name).blank?
      parts.push image_for(object) 
    end
    
    parts.push file_field(name)

    "#{parts.join("\n")}"
  end
  
  # Render form actions.
  # All forms get "Cancel", "Create" or "Cancel", "Update" actions, depending
  # on whether the current object is a new or an existing record.
  def actions(options)
    expect! options => { :cancel_url => String, :label => [ String, nil ] }

    div :class => "form-actions" do
      parts = []

      # 
      cancel_btn = link_to(I18n.t(:cancel), options[:cancel_url], :class => "btn")

      label = options[:label]
      label ||= object.new_record? ? I18n.t(:create) : I18n.t(:update)
      save_btn = submit(label, :class => "btn btn-primary")

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
end
