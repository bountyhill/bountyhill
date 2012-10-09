class AdminOnlyMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = ::Rack::Request.new(env)

    if request.session[:admin]
      @app.call(env) 
    else
      [403, {"Content-Type" => "text/plain"}, ["Only admins allowed here"]]
    end
  end
end
