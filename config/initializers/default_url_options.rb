# encoding: UTF-8

class Bountyhill::Application
  @@url_options = {
    host: "bountyhill.local:3000",
    protocol: "http"
  }
  
  def self.url_options=(url_options)
    @@url_options = url_options
  end

  def self.url_for(path, *args)
    protocol, host = @@url_options.values_at :protocol, :host

    path = File.join("#{protocol}://#{host}", path)
    CGI.build_url path, *args
  end
end
