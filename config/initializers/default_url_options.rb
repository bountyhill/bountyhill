class Bountyhill::Application
  @@url_options = {
    host: "bountyhill.local",
    protocol: "http"
  }
  
  def self.url_options=(url_options)
    @@url_options = url_options
  end

  def self.url_for(path, *args)
    path = File.join("#{protocol}://#{host}", path)
    CGI.build_url path, *args
  end
end
