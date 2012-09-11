class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  before_filter :set_locale

  protected
  
  around_filter :setup_access_control

  # enable ActiveRecord::AccessControl
  def setup_access_control(&block)
    ActiveRecord::AccessControl.as(current_user, &block)
  end

  def set_locale
    # TODO
    I18n.locale = I18n.default_locale
  end
end
