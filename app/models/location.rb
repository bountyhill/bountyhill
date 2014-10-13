# encoding: UTF-8

#
# The Location model records one objects location
class Location < ActiveRecord::Base 
  # the located object
  belongs_to :stationary, :polymorphic => true, :autosave => true

  # let geocoder perform the geocoding by setting latitude and longitude from address
  geocoded_by :address
  before_validation :geocode, :if => :geocode?

  attr_accessor :location
  attr_accessible :stationary, :stationary_id, :address, :radius, :location, :latitude, :longitude

  RADIUS = %w(unlimited 1 5 10 50 100 500 1000)
  
  validates_associated :stationary
  validates :address,   :presence => true
  validates :latitude,  :presence => true
  validates :longitude, :presence => true
#  validates :radius,    :presence => true, :inclusion => RADIUS

  def geocode?
    address_changed? and (latitude.blank? or longitude.blank?)
  end

  def unlimited?
    self.class.unlimited?(self.radius)
  end
  
  def self.unlimited?(radius)
    radius.to_s == 'unlimited'
  end

  #
  # when initializing location with request's location OpenStruct, given address ('name' attribute) might be 'ISO-8859-1' encoded
  # request.location: #<OpenStruct request="46.114.33.192", ip="46.114.33.192", country_code2="DE", country_code3="DEU", country_name="Germany", continent_code="EU", region_name="06", city_name="Georgsmarienh\xFCtte", postal_code="", latitude=52.19999999999999, longitude=8.050000000000011, dma_code=nil, area_code=nil, timezone="Europe/Berlin", name="Georgsmarienh\xFCtte, Germany">
  def address=(value)
    self[:address] =  if (_value = value.to_s).encode('utf-8').valid_encoding? then _value.encode('utf-8')
                      else                                                          _value.force_encoding("ISO-8859-1").encode('utf-8')
                      end
  end

end
