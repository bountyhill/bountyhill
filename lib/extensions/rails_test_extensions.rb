# encoding: UTF-8

module ActiveRecord::Assertions
  A = ActiveRecord::Assertions
  
  def self.invalid_attrs(object)
    return [] if object.valid?
    
    invalid_attrs = []
    object.errors.each do |key, msg|
      invalid_attrs << key
    end
    invalid_attrs
  end

  def assert_valid(object, *keys)
    invalid_attrs = A.invalid_attrs(object)
    if keys.empty?
      assert invalid_attrs.empty?, 
        "#{object.class.name} should be valid, but is not. Invalid attributes: #{invalid_attrs.map(&:inspect).join(", ")}"
    else
      invalid_keys = keys.map(&:to_sym) & invalid_attrs
      assert invalid_keys.empty?, 
        "#{object.class.name} #{invalid_keys.map(&:inspect).join(", ")} attribute(s) should be valid."
    end
  end

  def assert_invalid(object, *keys)
    invalid_attrs = A.invalid_attrs(object)
    if keys.empty?
      assert invalid_attrs.present?, 
        "#{object.inspect} should be invalid, but is not."
    else
      missing_invalid_keys = keys.map(&:to_sym) - invalid_attrs
      assert missing_invalid_keys.blank?,
        "#{object.class.name} #{missing_invalid_keys.map(&:inspect).join(", ")} attribute(s) should be invalid."
    end
  end
end

