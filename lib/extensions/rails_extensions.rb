# encoding: UTF-8

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

# -- system wide object ids.

class ActiveRecord::Base
  def self.by_uid(uid)
    return unless uid.is_a?(String)
    
    if uid =~ /^([a-zA-Z_][a-zA-Z_0-9:]*)#(\d+)$/
      $1.constantize.find($2)
    end
  rescue NameError
  end

  def self.by_uid!(uid)
    by_uid(uid) || raise(ActiveRecord::RecordNotFound, "Could not find #{uid.inspect}")
  end
  
  def uid
    "#{self.class.model_name}##{id}" unless new_record?
  end
end

class NilClass
  def uid
    nil
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

# -- automatically count the metric for this class.

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
  M = ActiveRecord::Base::MoneySupport unless const_defined?('M')

  # return the name of the cents column
  def self.cents_column(column) #:nodoc:
    cents_column = "#{column}_in_cents"
  end
  
  def money(column, options = {})
    # make sure the MoneySupport::Validation module is included.
    if options[:validate] != false
      include Validation
    end
    
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
  # Supported options:
  #
  #   :currency => true             # show or hide currency
  #   :thousands_separators => true # show or hide thousands_separators
  #   :cents => true                # include cents or not.
  def to_s(options = {})
    defaults = {currency: true, cents: true, thousands_separators: true}

    # Text transformation options
    options = defaults.merge(options)

    # get numerical part
    amount = cents / currency.subunit_to_unit.to_f 
    
    if options[:cents]
      subunit_length = currency.subunit_to_unit.to_s.length - 1
      s = amount.round(subunit_length).to_s
    else
      s = amount.round(0).to_s
    end
    
    # adjust thousands_separator and decimal_mark
    parts = s.split('.')
    if options[:thousands_separators]
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{currency.thousands_separator}")
    end
    s = parts.join(currency.decimal_mark)
    
    # add currency
    if options[:currency]
      if currency.symbol_first
        s = "#{currency.symbol} #{s}"
      else
        s = "#{s} #{currency.symbol}"
      end
    end
    
    if options[:nbsp]
      s.gsub!(" ", "\u00a0") # "\u00a0" is the non breakable space UTF8 character
    end
    
    s.html_safe
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

class Module
  def reload
    source_file = "#{name.underscore}.rb"
    load source_file
    STDERR.puts "Loaded #{source_file}"
  rescue StandardError
    STDERR.puts "Cannot load #{source_file}: #{$!}, from\n\t#{$!.backtrace.join("\n\t")}"
  end
end