class ActiveModel::Errors
  def inspect
    "<#{self.class}:#{"%x" % object_id} #{full_messages.join(", ")}>"
  end
end

class ActiveRecord::Base
  # returns the first error message for a given attribute
  def error_message_for(attribute)
    errors = self.errors || {}
    error_messages = errors[attribute] || []
    error_messages.first
  end
end

# -- included RandomID to have newly created models have a random ID.

module ActiveRecord::RandomID
  def self.included(klass)
    klass.before_create :set_random_id
  end
  
  def set_random_id
    return if self.id
    
    while true do
      self.id = SecureRandom.random_number(0x80000000)
      break if self.class.first(:conditions => { :id => self.id }).nil?
    end
  end
end

# -- add a ActiveRecord::Base.money method to help set up money columns.

module ActiveRecord::Base::MoneySupport
  M = ActiveRecord::Base::MoneySupport
  
  def money(column)
    cents_column = "#{column}_in_cents"
    
    validates_numericality_of cents_column, :greater_than_or_equal_to => 0

    composed_of column,
      :class_name   => "Money",
      :mapping      => [ [ cents_column, "cents" ] ],
      :constructor  => M.method(:construct_money),
      :converter    => M.method(:convert_to_money)
  end
  
  def self.construct_money(cents)
    Money.new(cents || 0, Money.default_currency)
  end
  
  def self.convert_to_money(value)
    unless value.respond_to?(:to_money)
      raise(ArgumentError, "Can't convert #{value.class} to Money")
    end
    value.to_money
  end
end

ActiveRecord::Base.extend ActiveRecord::Base::MoneySupport

class Money
  def to_full_string
    "#{self} #{currency_as_string}"
  end
end

# -- extend FormBuilder with a control_group method which renders
#    a default control group for Twitter Bootstrap forms. 

ActionView::Helpers::FormBuilder

class ActionView::Helpers::FormBuilder
  extend Forwardable
  delegate [:error_class_for, :error_message_for, :link_to, :image_for] => :@template
  delegate :readonly? => :object

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
  def div_tag(*args, &block)
    content_tag :div, *args, &block
  end

  DEFAULT_INPUT_FIELD_OPTIONS = {
    :text_field     => { :class => "input-xlarge" },
    :password_field => { :class => "input-xlarge" },
    :text_area      => { :class => "input-xlarge" }
  }
  
  # Creating a control_group.
  def control_group(name, field_type = :text_field, input_field_options = {})
    expect! respond_to?(field_type), object.respond_to?(name)
    
    if default_input_field_options = DEFAULT_INPUT_FIELD_OPTIONS[field_type]
      input_field_options = default_input_field_options.merge(input_field_options)
    end

    if readonly?
      input_field_options[:readonly] = true
    end
    
    div_tag :class => "control-group #{error_class_for(object, name)}" do
      label = self.label name, :class => "control-label"
      controls = div_tag :class => "controls" do
        input_field = self.send field_type, name, input_field_options
        errors = error_message_for(object, name)
        "#{input_field}\n#{errors}\n"
      end
      
      "#{label}\n#{controls}"
    end
  end

  def transloadit(name, options)
    parts = []
    parts.push @template.transloadit(:upload) unless readonly?

    unless object.send(name).blank?
      parts.push image_for(object) 
    end
    
    parts.push file_field(name) unless readonly?

    "#{parts.join("\n")}"
  end
  
  def actions(additional_actions = {})
    div_tag :class => "form-actions" do
      parts = []

      unless readonly?
        label = object.new_record? ? :create : :update
        parts.push submit(I18n.t(label), :class => "btn btn-primary")
      end
      
      parts.concat additional_actions.map { |label, target|
        link_to(I18n.t(label), target, :class => "btn")
      }
      
      parts.join(" ")
    end
  end
end
