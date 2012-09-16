module ApplicationController::ImageParameters
  def self.included(klass)
    klass.send :include, Transloadit::Rails::ParamsDecoder
  end

  private
  
  #
  # returns a hash describing a remote image resource:
  #
  #  
  def image_param
    return unless transloadit = params["transloadit"]
    return unless results = transloadit["results"]
    
    results.inject({}) do |hash, (key, values)|
      value = values.first
      url, mime, size, meta = *value.values_at(:url, :mime, :size, :meta)
      width, height = meta.values_at(:width, :height)
      
      hash.update key.to_s.gsub(/^:/, "").to_sym => {
        url: url,
        mime: mime,
        size: size,
        width: width,
        height: height
      } 
    end
  end
end
