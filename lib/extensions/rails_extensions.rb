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
