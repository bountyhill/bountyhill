# encoding: UTF-8

require_relative "../test_helper.rb"

class LocationTest < ActiveSupport::TestCase
  
  def test_validation
    location = Location.new
    assert !location.valid?
    assert_equal [:address, :latitude, :longitude], location.errors.keys.sort

    # latitude und longitude are filled out automatically
    # when address is known
    location.address = "Berlin, Germany"
    assert location.valid?
    assert_equal 52, location.latitude.to_i
    assert_equal 13, location.longitude.to_i
  end
  
  def test_factory
    assert_difference "Quest.count" do
      assert_difference "Location.count" do
        location = Factory(:location)
        assert location.valid?
      end
    end
  end
  
  def test_unlimited?
    location = Location.new
    assert !location.unlimited?
    
    Location::RADIUS.each_with_index do |radius, index|
      location.radius = radius
      if radius == 'unlimited'
        assert location.unlimited?          # check instance method
        assert Location.unlimited?(radius)  # check class method
      else
        assert !location.unlimited?         # check instance method
        assert !Location.unlimited?(radius) # check class method
      end
    end
  end
  
end