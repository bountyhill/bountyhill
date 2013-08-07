# encoding: UTF-8

class ActivitiesController < ApplicationController
  
  def index
    @activities = current_user.activities.paginate(
      :page     => params[:page],
      :per_page => per_page,
      :order    => "created_at DESC",
      :include  => :user)
  end
  
end