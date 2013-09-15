# encoding: UTF-8

class UsersController < ApplicationController
  FORM_PARTIALS = %w(profile address email twitter facebook delete) unless const_defined?("FORM_PARTIALS")

  before_filter :set_user
  before_filter :access_allowed?,   :except => [:show]
  before_filter :remove_user_image, :only   => [:update]
  before_filter :set_partials,      :only   => [:edit, :update]
  
  def show
    @per_page = per_page
  end

  def edit
    render :layout => 'dialog'
  end
  
  def update
    @user.attributes = params[:user]
    if @user.save
      flash[:success] = I18n.t("message.update.success", :record => @user.name)
      redirect_to! @user
    end

    set_partials
    render :action => "edit"
  end
  
  def destroy
    @user.update_attributes(params[:user])
    @user.soft_delete!
    signout
    redirect_to root_path
  end
  
private
  
  def set_user
    @user = if params[:id] then User.find(params[:id])
            else current_user
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
  
  def set_partials
    if (@partials = FORM_PARTIALS.select{ |partial| params[partial] }).blank?
      @partials = FORM_PARTIALS
    end
    
    @partials
  end

end
