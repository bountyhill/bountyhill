module SessionsHelper
  User
  
  def sign_in(user)
    expect! user => User
    
    session[:remember_token] = user.remember_token
    @current_user = user
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
  
  # This reads the twitter oauth configuration from the :tw session entry.
  # The :tw session entry is filled in initially as the result of 
  # Twitter's oauth callback, which is handled by TwitterAuthMiddleware.
  # (see lib/middleware/twitter_auth_middleware.rb)
  def signin_from_twitter_session #:nodoc:
    W "twitter_session", session[:tw]
    
    parts = session[:tw].to_s.split("|")
    return if parts.length != 3

    identity = twitter_identity :name => parts[0], 
                  :oauth_token => parts[1], 
                  :oauth_secret => parts[2]

    sign_in(identity.user)
    
    # We no longer need the :tw entry in the session. The user is
    # logged in, and its auth keys should be stored in the DB.
    session.delete :tw
  end
  
  # return the twitter_identity according to the auth hash received
  # from twitter.
  def twitter_identity(auth)
    if @current_user
      if identity = @current_user.identity(:twitter)
        identity.update_auth!(auth)
      else
        identity = Identity::Twitter.new(auth)
        identity.user = @current_user
        identity.save!
      end
    else
      if identity = Identity::Twitter.find_by_name(auth[:name])
        identity.update_auth! auth
      else
        identity = Identity::Twitter.create!(auth)
      end
    end
  
    identity
  end
end
