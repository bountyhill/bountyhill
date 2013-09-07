# encoding: UTF-8

class UsersController < ApplicationController
  before_filter :set_user
  before_filter :access_allowed?,   :except => [:show]
  before_filter :remove_user_image, :only   => [:update]
  
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
    # TODO: refactor this, e.g. by providing actions in particular identities controllers!
    
    case params[:section]
    when "passwd"
      identity = params["identity"] || {}
      password = params["identity"].delete("password")
      
      unless Identity::Email.authenticate @email.email, password  
        @email.errors.add :password, I18n.t("message.password_invalid")
      else
        if @email.update_attributes(
            :password               => identity[:password_new],
            :password_confirmation  => identity[:password_new_confirmation])
            
          flash[:success] = I18n.t("message.update.success", :record => Identity::Email.human_attribute_name(:password))
          redirect_to! @user
        end
      end
      
    else
      @user.attributes = params[:user]
      if @user.save
        flash[:success] = I18n.t("message.update.success", :record => @user.name)
        redirect_to! @user
      end
    end

    @partials = EDIT_PARTIALS
    render :action => "edit"
  end
  
  def destroy
    params[:user] ||= {}

    if params[:user][:delete_me].to_i.zero?
      @user.errors.add :delete_me, I18n.t("message.check_delete_me")
      redirect_to! @user
    end
    
    @user.update_attribute(:delete_reason, params[:user][:delete_reason])
    @user.soft_delete!
    signout
    redirect_to root_path
  end
  
  private
  
  def set_user
    @user = if params[:id] then User.find(params[:id])
            else current_user
            end

    if @user and @user == current_user
      @user.extend DummyParameters
      @email = @user.identity(:email)
      @email.extend DummyParameters
    end
  end

  def access_allowed?
    return if @user == current_user
    
    flash[:error] = I18n.t("message.access.not_allowed")
    redirect_to root_path
  end
  
  #
  # removes user's image if not given in user's params hash
  def remove_user_image
    return unless params[:section] == "profile"
    
    params[:user][:images] = [] unless params[:user] && params[:user].key?(:images)
  end
  
  module DummyParameters
    attr :password
    attr :password_new
    attr :password_new_confirmation
    attr :email_new
    attr :delete_me
  end
end
