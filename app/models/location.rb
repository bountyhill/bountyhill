# encoding: utf-8

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

  RADIUS = %w(1 2 5 10 25 50 100 250 500 1000 unlimited)
  
  validates_associated :stationary
  validates :address,   :presence => true
  validates :latitude,  :presence => true
  validates :longitude, :presence => true
#  validates :radius,    :presence => true, :inclusion => RADIUS

  def initialize(attributes={}, options={})
    super
    
    if (location = attributes.delete(:location))
      self.address    = location.name
      self.latitude   = location.latitude
      self.longitude  = location.longitude
    end
    
    self
  end

  def geocode?
    address_changed? and (latitude.blank? or longitude.blank?)
  end

  def unlimited?
    self.radius == 'unlimited'
  end
  
  def self.unlimited?(radius)
    radius.to_s == 'unlimited'
  end

end