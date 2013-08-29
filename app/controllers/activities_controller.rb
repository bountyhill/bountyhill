# encoding: UTF-8

class ActivitiesController < ApplicationController
  before_filter :set_user, :only => [:index]
  
  def index
    @activities = @user.activities.paginate(
      :page     => params[:page],
      :per_page => per_page,
      :order    => "created_at DESC",
      :include  => :user)
  end
  
private

  def set_user
    # since activities are shown on user/show page
    # params[:id] equals the displayed user's id
    @user = if params[:id] then User.find(params[:id])
            else current_user
            end
  end
end