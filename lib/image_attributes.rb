module ImageAttributes
  
  def images(options = {})
    expect! options => {
      :width => [Fixnum, nil],
      :height => [Fixnum, nil]
    }
    
    urls = serialized[:images] || []
    urls.map { |url| Filepicker.url url, options }
  end
  
  def images=(urls)
    expect! urls => [ Array, nil ]
    serialized[:images] = urls
  end

  module Filepicker
    extend self
    
    # return a filepicker.io URL constructed from the base_url and the
    # passed in options.
    #
    # Supported options include:
    # - :width
    # - :height
    def url(base_url, options)
      base_url + instruction(options)
    end
    
    private
    
    FORMAT = "jpg&quality=20"

    # generate Filepicker conversion instruction from options.
    # This method can easily be memoized.
    def instruction(options)
      width, height = options.values_at :width, :height

      # conversion needed?
      command = "/convert" if width || height 
      
      #
      params = []
      
      # evaluate width and height
      if width && height
        params << "fit=crop&w=#{width}&h=#{height}&format=#{FORMAT}"
      elsif width
        params << "fit=scale&w=#{width}&format=#{FORMAT}"
      elsif height
        params << "fit=scale&h=#{height}&format=#{FORMAT}"
      end
      
      # enable caching, set content disposition
      params << "cache=true"
      params << "dl=false"

      "#{command}?" + params.join("&")
    end
  end
  
end