require_dependency "identity/twitter"

module SessionsHelper
  def sign_in(user)
    expect! user => User
    
    session[:remember_token] = user.remember_token

    @current_user = user

    if transfers = session.delete(:transfer)
      user.transfer!(transfers)
    end
  end
  
  def sign_out
    @current_user = false
    
    session.delete(:remember_token)   # Delete the BH remember token
    session.delete(:tw)               # Delete the twitter auth token
  end
  
  def signed_in?
    current_user
  end

  def admin?
    current_user && current_user.admin?
  end

  # returns the current_user. When called in a request for the first 
  # time, this method tries to fetch or create the current_user by 
  # evaluating the remember_token and/or the twitter session.
  #
  # This returns either a User object or nil.
  def current_user
    if @current_user.nil?
      signin_from_remember_token
      signin_from_twitter_session
      @current_user ||= false
    end
    
    @current_user || nil
  end
  
  def signin_from_remember_token #:nodoc:
    if remember_token = session[:remember_token]
      @current_user = User.find_by_remember_token(remember_token)
    end
  end
  
  # This reads the twitter oauth configuration from the session, via the
  # TwitterAuthMiddleware (see lib/middleware/twitter_auth_middleware.rb), 
  # and loads or creates an Identity accordingly.
  def signin_from_twitter_session #:nodoc:
    screen_name, oauth_token, oauth_secret, info = *TwitterAuthMiddleware.session_info(session)
    return unless screen_name

    identity = ::Identity::Twitter.find_or_create :info => info, 
                  :user => current_user,
                  :screen_name  => screen_name,
                  :oauth_token  => oauth_token,
                  :oauth_secret => oauth_secret

    sign_in(identity.user)
  end
end
