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

# -- support for serialized_attributes.

class ActiveRecord::Base
  def self.serialized_attr(*attribute_names)
    attribute_names.each do |name|
      define_method name        do 
        serialized[name] 
      end
      define_method "#{name}="  do |value| 
        serialized[name] = value 
      end
    end
  end
end

# -- support for serialized_attributes.

class ActiveRecord::Base
  def self.with_metrics!(name)
    after_create do
      Bountybase.metrics.count name
    end
  end
end

# -- include ActiveRecord::RandomID to have newly created models have a random ID.

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

  # return the name of the cents column
  def self.cents_column(column) #:nodoc:
    cents_column = "#{column}_in_cents"
  end
  
  def money(column)
    # make sure the MoneySupport::Validation module is included.
    include Validation

    composed_of column,
      :class_name   => "Money",
      :mapping      => [ [ M.cents_column(column), "cents" ] ],
      :constructor  => M.method(:construct_money),
      :converter    => M.method(:convert_to_money)
  end

  def money_attributes
    @money_attributes ||= attribute_names.map { |name| name.gsub!(/_in_cents/, "") }.compact
  end
  
  module Validation
    def self.included(other)
      other.validate :validate_money
    end
    
    def validate_money
      self.class.money_attributes.each do |attr|
        cents = self.send M.cents_column(attr)
        cents = Integer(cents) rescue nil
        if !cents || cents < 0
          errors.add attr, I18n.t(:greater_than_or_equal_to, :count => 0)
        end
      end 
    end
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

  def to_short_string
    "#{to_s.gsub(/\..*/, "")} #{currency_as_string}"
  end
end

# -- extend FormBuilder with a control_group method which renders
#    a default control group for Twitter Bootstrap forms. 

ActionView::Helpers::FormBuilder

class ActionView::Helpers::FormBuilder
  extend Forwardable
  delegate [:error_class_for, :error_message_for, :link_to, :image_for] => :@template

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
  def control_group(*args)
    input_field_options = args.extract_options!
    
    name, field_type = *args
    field_type ||= :text_field
    
    raise ArgumentError, "Invalid field_type #{field_type.inspect}" unless respond_to?(field_type)
    raise ArgumentError, "Invalid attribute #{object.class.name}##{name.inspect}" unless object.respond_to?(name)
    
    if default_input_field_options = DEFAULT_INPUT_FIELD_OPTIONS[field_type]
      input_field_options = default_input_field_options.merge(input_field_options)
    end

    if field_type == :hidden_field
      return self.send field_type, name, input_field_options
    end

    label = input_field_options.delete(:label)
    div :class => "control-group #{error_class_for(object, name)}" do
      label_tag = self.label label || name, :class => "control-label"
      controls = div :class => "controls" do
        input_field = self.send field_type, name, input_field_options
        errors = error_message_for(object, name)
        "#{input_field}\n#{errors}\n"
      end
      
      "#{label_tag}\n#{controls}"
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
        I18n.t "agree_to_terms"
      end
    end
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
    expect! options => { :cancel_url => String }

    div :class => "form-actions" do
      parts = []

      # 
      cancel_btn = link_to(I18n.t(:cancel), options[:cancel_url], :class => "btn")
      save_btn = submit(I18n.t(object.new_record? ? :create : :update), :class => "btn btn-primary")

      "#{cancel_btn} #{save_btn}"
    end
  end
end

class Date
  def to_js
    "new Date(#{year}, #{month-1}, #{day})"
  end
end

require 'zlib' 

class String
  def crc32
    Zlib::crc32(self)
  end
end
