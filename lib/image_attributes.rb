module ImageAttributes
  
  def images(size = {})
    width, height = size.values_at(:width, :height)
    urls = serialized[:images] || []
    
    if width && height
      expect! width => Fixnum, height => Fixnum
    
      # set width and height; see https://developers.filepicker.io/docs/web/#fpurl
      urls = urls.map { |url| "#{url}/convert?w=#{width}&h=#{height}" }
    end

    # set content disposition; see https://developers.filepicker.io/docs/web/#fpurl
    urls.map { |url| "#{url}?dl=false" }
  end
  
  def images=(urls)
    expect! urls => [ Array, nil ]
    serialized[:images] = urls
  end

  def original_image_url
    original = image && image["original"]
    url = original && original["url"]

    # If the original URL already points to an imgio instance; i.e. if it looks like
    # this: "http://imgio.heroku.com/jpg/fill/90x90/http://some.where/123456.jpg",
    # the following line extracts the original URL from the imgio URL.
    url.gsub(/.*\d\/http/, "http") if url
  end
  
end