class UsersController < ApplicationController
  before_filter :set_user
  
  def show
    request_identity!
  end
  
  def update
    case params["section"]
    when "passwd"
      identity = params["identity"] || {}
      password_old = params["identity"].delete("password_old")
      unless Identity::Email.authenticate @email.email, password_old  
        @email.errors.add :password_old, "Invalid password."
      else
        @email.attributes = identity
        @email.valid?
      end
      
      if @email.errors.blank?
        @email.save!
        redirect_to! @user
      end
    else
      @user.attributes = params["user"]
      redirect_to! @user if @user.save
    end

    render :action => "show"
  end
  
  def destroy
    user = params["user"] || {}
    if user["delete_me"].to_i == 0
      @user.errors.add :delete_me, I18n.t("user.message.check_delete_me")
      render! :action => :show
    end
    
    # TODO: evaluate the :description field; e.g. send email to admin
    @user.soft_delete!
    signout
    redirect_to "/"
  end
  
  private
  
  def set_user
    @user = current_user
    @user.extend DummyParameters

    if @user
      @email = @user.identity(:email)
      @email.extend DummyParameters
    end
  end
  
  module DummyParameters
    attr :delete_me
    attr :password_old
  end
end
