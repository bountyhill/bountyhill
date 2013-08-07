# encoding: UTF-8

module AccessControlAssertions
  def assert_cannot_write(*objects)
    objects.each do |object|
      assert_raise(ActiveRecord::RecordInvalid) {  
        object.update_attributes! "title" => "title #{rand(100000)}"
      }
    end
  end

  def assert_can_destroy(*objects)
    objects.each do |object|
      assert_nothing_raised() {  
        object.destroy
      }
    end
  end
  
  def assert_cannot_destroy(*objects)
    objects.each do |object|
      assert_raise(ActiveRecord::RecordInvalid) {  
        object.destroy
      }
    end
  end

  def assert_can_write(*objects)
    objects.each do |object|
      assert_nothing_raised() {  
        object.update_attributes! "title" => "title #{rand(100000)}"
      }
    end
  end
  
  def assert_cannot_read(*objects)
    objects.each do |object|
      assert_raise(ActiveRecord::RecordNotFound) {  
        Quest.find(object.id)
      }
    end
  end

  def assert_can_read(*objects)
    objects.each do |object|
      assert_nothing_raised() {  
        assert_equal(object, Quest.find(object.id))
      }
    end
  end
end
