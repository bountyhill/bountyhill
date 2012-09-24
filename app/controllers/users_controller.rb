class UsersController < ApplicationController
  TABS = %w(overview account contact financial)

  def show
    @user = current_user
  end
  
  private
  
  def self.default_tab
    TABS.first
  end

  def active_tab
    params[:tab] || UsersController.default_tab
  end
  
  helper_method :current_tabs, :active_tab
  def current_tabs
    TABS
  end
end
