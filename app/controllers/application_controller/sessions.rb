require_dependency "identity/twitter"

module ApplicationController::Sessions
  def self.included(klass)
    klass.helper_method :current_user, :admin?
  end

  def signin(user)
    expect! user => User
    
    session[:remember_token] = user.remember_token
    @current_user = user
  end
  
  def signout
    @current_user = false
    
    session.delete(:remember_token)
    session.delete(:signedin)

    ApplicationController::RequiredIdentity.set_payload session, nil
  end
  
  def admin?
    current_user && current_user.admin?
  end

  def identity?(*args)
    current_user && current_user.identity(*args)
  end

  # returns the current_user. When called in a request for the first 
  # time, this method tries to fetch or create the current_user by 
  # evaluating the remember_token and/or the twitter session.
  #
  # This returns either a User object or nil.
  def current_user
    if @current_user.nil?
      if remember_token = session[:remember_token]
        @current_user = User.find_by_remember_token(remember_token)
        # run_after_signin if @current_user
      end

      @current_user ||= false
    end
    
    @current_user || nil
  end
end
