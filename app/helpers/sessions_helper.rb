module SessionsHelper

  def sign_in(user)
    expect! user => User
    
    session[:remember_token] = user.remember_token
    current_user = user
  end

  def sign_out
    current_user = nil
    session.delete(:remember_token)
  end
  
  def signed_in?
    !current_user.nil?
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= if remember_token = session[:remember_token]
      User.find_by_remember_token(remember_token)
    end
  end
end
