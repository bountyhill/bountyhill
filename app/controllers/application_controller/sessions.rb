# encoding: UTF-8

require_dependency "identity/twitter"
require_dependency "identity/facebook"
require_dependency "identity/google"
require_dependency "identity/linkedin"
require_dependency "identity/xing"

module ApplicationController::Sessions
  def self.included(klass)
    klass.helper_method :current_user, :admin?, :signin_identity
  end

  def signin(user, identity=nil)
    identity ||= user.identities.last
    
    expect! user      => User
    expect! identity  => Identity
    
    session.update(
      :remember_token => user.remember_token,
      :signedin_with  => "#{identity.provider}##{identity.id}",
      :admin          => user.admin?,
    )
    @current_user = user
  end
  
  def signout
    session.delete(:signedin_with) if @current_user.deleted?

    session.delete(:remember_token)
    session.delete(:admin)

    @current_user = false

    ApplicationController::RequiredIdentity.set_payload session, nil
  end
  
  def admin?
    current_user && current_user.admin?
  end
    
  def signin_identity
    @signin_identity ||= begin
      if session[:signedin_with].present?
        provider, id = session[:signedin_with].to_s.split('#')
        "Identity::#{provider.camelize}".constantize.find_by_id(id.to_i) if id.present?
      end
    end
  end
  
  def identity?(*args)
    current_user && current_user.reload.identity(*args)
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
