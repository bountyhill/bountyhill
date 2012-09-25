module ImageAttributes
  def original_image_url
    original = image && image["original"]
    url = original && original["url"]

    # If the original URL already points to an imgio instance; i.e. if it looks like
    # this: "http://imgio.heroku.com/jpg/fill/90x90/http://some.where/123456.jpg",
    # the following line extracts the original URL from the imgio URL.
    url.gsub(/.*\d\/http/, "http") if url
  end
end