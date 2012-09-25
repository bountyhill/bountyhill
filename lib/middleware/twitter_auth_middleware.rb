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
  
  def twitter_callback
    login_from_twitter_callback
    redirect @success_url
  rescue OAuth::Unauthorized
    redirect @failure_url
  end
  
  # log in from twitter callback. Raise OAuth::Unauthorized if authorization
  # fails.
  def login_from_twitter_callback
    tw_request_token = session.delete "tw_request_token"
    tw_request_token_secret = session.delete "tw_request_token_secret"

    client = twitter_client

    access_token = client.authorize(tw_request_token, tw_request_token_secret, 
      :oauth_verifier => params[:oauth_verifier])
    raise OAuth::Unauthorized, "Unauthorized" unless client.authorized?

    info = client.info
    session.update "twinfo" => info.values_at(*TWINFO_KEYS)
    session.update "twauth" => "#{info["screen_name"]}|#{access_token.token}|#{access_token.secret}"
  end
  
  TWINFO_KEYS = %w(
    id followers_count friends_count lang location name
    profile_image_url profile_image_url_https statuses_count
  )
  
  def self.get_session_info(session)
    twinfo = session["twinfo"]
    return unless twinfo.is_a?(Array) && twinfo.length == TWINFO_KEYS.length
  
    {}.tap do |info|
      TWINFO_KEYS.each_with_index { |key, idx| info[key] = twinfo[idx] }
    end
  end
  
  def self.session_info(session)
    parts = session["twauth"].to_s.split("|")
    return unless parts.length == 3
    
    screen_name, oauth_token, oauth_secret = *parts
    [ screen_name, oauth_token, oauth_secret, get_session_info(session) ]
  ensure
    session.delete "twauth"
    session.delete "twinfo"
  end
end
