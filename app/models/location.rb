# encoding: utf-8

#
# The Location model records one objects location
class Location < ActiveRecord::Base 
  attr_accessor :location
  # let geocoder perform the geocoding by setting latitude and longitude from address
  # geocoded_by :address
  # after_validation :geocode, :if => :address_changed?

  # Gmaps4rails has an optional geocoding feature which calculates the lat and long needed to plot a location.
  # It's turned off here since geocoder provides latitude and longitude already.
  # see https://github.com/apneadiving/Google-Maps-for-Rails/wiki/Model-Customization
  acts_as_gmappable :process_geocoding => false 

  # the located object
  belongs_to :stationary, :polymorphic => true, :autosave => true

  attr_accessible :stationary, :stationary_id, :address, :radius, :location, :latitude, :longitude

  RADIUS = %w(1 2 5 10 25 50 100 200 500 unlimited)
  
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

end
