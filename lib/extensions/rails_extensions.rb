class ActiveModel::Errors
  def inspect
    "<#{self.class}:#{"%x" % object_id} #{full_messages.join(", ")}>"
  end
end

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
