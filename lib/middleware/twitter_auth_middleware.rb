require "twitter_oauth"
require "forwardable"

class TwitterAuthMiddleware
  extend Forwardable
  
  # -- middleware starts here
  
  def initialize(app, options = {})
    options.symbolize_keys!

    expect! options => { 
      :consumer_key => String,
      :consumer_secret => String,
      :failure_url => String,
      :success_url => String
    }

    @app = app
    @twitter_oauth = {
      :consumer_key    => options[:consumer_key],
      :consumer_secret => options[:consumer_secret]
    }

    @failure_url, @success_url = options.values_at(:failure_url, :success_url)

    @path = options[:path] || 'tw'
    @matcher = /^\/#{@path}\/(login|logout|callback)$/
  end
  
  
  def call(env)
    return @app.call(env) unless @matcher =~ env["PATH_INFO"]

    begin
      @request = ::Rack::Request.new(env)
      self.send "twitter_#{$1}"
    ensure
      @request = nil
    end
  end

  private
  
  delegate [:session, :params] => :@request
  
  def twitter_client
    TwitterOAuth::Client.new @twitter_oauth
  end
  
  def logout_from_session!
    session.delete :tw
  end
  
  def oauth_callback
    "#{@request.scheme}://#{@request.host_with_port}/#{@path}/callback"
  end
  
  def redirect(location)
    body = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
    [302, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
  end
  
  def twitter_login
    logout_from_session!

    # -- request a new access token from twitter.
    request_token = twitter_client.request_token(:oauth_callback => oauth_callback)
    session.update "tw_request_token" => request_token.token, 
      "tw_request_token_secret" => request_token.secret

    redirect request_token.authorize_url
  end
  
  def twitter_logout
    logout_from_session!
    redirect "/"
  end
  
  # log in from twitter callback. Raise OAuth::Unauthorized if authorization
  # fails.
  def login_from_twitter_callback
    tw_request_token, tw_request_token_secret = 
      session.values_at "tw_request_token", "tw_request_token_secret"

    client = twitter_client

    access_token = client.authorize(tw_request_token, tw_request_token_secret, 
      :oauth_verifier => params[:oauth_verifier])
    raise OAuth::Unauthorized, "Unauthorized" unless client.authorized?
    
    session.delete "tw_request_token"
    session.delete "tw_request_token_secret"
    session.update "tw" => [client.info["name"], access_token.token, access_token.secret].join("|")
  end
  
  def twitter_callback
    login_from_twitter_callback
    redirect @success_url
  rescue OAuth::Unauthorized
    redirect @failure_url
  end
end
