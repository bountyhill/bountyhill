# encoding: UTF-8

class UsersController < ApplicationController
  before_filter :set_user
  
  def show
    @per_page = per_page
  end
  
  EDIT_PARTIALS = %w(profile address password email twitter delete)
  def edit
    @partials = EDIT_PARTIALS.select{ |partial| params[partial] }
    @partials = EDIT_PARTIALS if @partials.blank?
    
    render :layout => 'dialog'
  end
  
  def update
    case params["section"]
    when "passwd"
      identity = params["identity"] || {}
      password = params["identity"].delete("password")
      unless Identity::Email.authenticate @email.email, password  
        @email.errors.add :password, I18n.t("message.password_invalid")
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
      @user.errors.add :delete_me, I18n.t("message.check_delete_me")
      render! :action => :show
    end
    
    # TODO: evaluate the :description field; e.g. send email to admin
    @user.soft_delete!
    signout
    redirect_to "/"
  end
  
  private
  
  def set_user
    @user = if params[:id]
      User.find(params[:id], :readonly => (@action == "show"))
    else
      current_user
    end
    
    if @user and @user == current_user
      @user.extend DummyParameters
      @email = @user.identity(:email)
      @email.extend DummyParameters
    end
  end
  
  module DummyParameters
    attr :password
    attr :password_new
    attr :password_new_confirmation
    attr :email_new
    attr :delete_me
  end
end
