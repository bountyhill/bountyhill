# encoding: UTF-8

class ErrorsController < ApplicationController
  before_filter :set_exception
  before_filter :set_error

  def not_found
    respond_to do |format|
      format.html { render :status => 404, :template => "errors/show" }
      format.any  { render :status => 404, :text => "Not Found" }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html { render :status => 422, :template => "errors/show" }
      format.any  { render :status => 422, :text => "Unprocessable Entity" }
    end
  end

  def internal_server_error
    # render file: "#{Rails.root}/public/500.html", layout: false, :status => 500
    respond_to do |format|
      format.html { render :status => 500, :template => "errors/show" }
      format.any  { render :status => 500, :text => "Internal Server Error" }
    end
  end
  
private

  def set_exception
    @exception = env["action_dispatch.exception"]
  end

  def set_error
    @error = (env["action_dispatch.request.path_parameters"] || params)[:action]
  end
end