class PublicCacheControl
  attr_reader :path, :max_age
  
  def initialize(app, options)
    expect! options => { :path => [Regexp, nil], :max_age => Integer }

    @app = app
    @path = options[:path] || /^\/assets\//
    @max_age = options[:max_age]
  end
  
  def call(env)
    result = @app.call(env)
    if env["REQUEST_PATH"] =~ path
      headers = result[1]
      headers["Cache-Control"] = "public, max-age=#{max_age}"
      headers["Expires"] = (Time.now + max_age).utc.rfc2822
    end
    result
  end
end
