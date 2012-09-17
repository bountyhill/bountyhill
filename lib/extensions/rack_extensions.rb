require "ostruct"
require "geoip"

class Rack::Request
  # Default parts for the :location entry.
  LOCATION_PARTS = [ :city_name, :country_name ]
  
  # geo_ip looks up a given IP address, and returns an OpenStruct
  # with entries location.latitude, location.longitude, location.name
  #
  def location
    return unless city = geo_lite_city

    city[:name] = LOCATION_PARTS.map { |key| city[key] }.compact.join(", ")
    OpenStruct.new city
  end


  # lookup an IP's location from the GeoLiteCity database.
  def geo_lite_city
    if @geo_lite_city.nil?
      ip = self.ip
      
      # Try to resolve global IP if we are running locally.
      if ip == "127.0.0.1"
        ip = Rack::Request.find_global_ip 
      end
      
      if ip
        if city = Rack::Request.geo_lite_city.city(ip)
          @geo_lite_city = city.to_hash
        end
      end
      @geo_lite_city ||= false
    end
    
    @geo_lite_city || nil
  end

  def self.find_global_ip
    if @globalip.nil?
      @globalip = begin
        Timeout.timeout(5) {
          Net::HTTP.get(URI('http://globalip.herokuapp.com'))
        }
      rescue Timeout::Error
        false
      end
    end

    @globalip || nil
  end
  
  def self.geo_lite_city #:nodoc:
    @geo_ip ||= ::GeoIP.new("data/GeoLiteCity.dat")
  end
end
