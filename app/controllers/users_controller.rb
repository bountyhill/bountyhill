class UsersController < ApplicationController
  TABS = %w(overview email twitter contact financial balance payments)

  def show
    @user = current_user
  end
  
  private
  
  def active_tab
    params[:tab] || UsersController.default_tab
  end
  
  def self.default_tab
    TABS.first
  end

  helper_method :active_tab
end
