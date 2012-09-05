class ActiveModel::Errors
  def inspect
    "<#{self.class}:#{"%x" % object_id} #{full_messages.join(", ")}>"
  end
end

module ActiveRecord::Base
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

module ActiveRecord::Base::MoneySupport
  def money(column)
    composed_of column,
      :class_name => "Money",
      :mapping => [["#{column}_cents", "#{column}_cents"]],
      :constructor => Proc.new { |cents| Money.new(cents || 0, Money.default_currency) }
  end
end

ActiveRecord::Base.extend ActiveRecord::Base::MoneySupport
