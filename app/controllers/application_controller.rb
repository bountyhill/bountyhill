class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  before_filter :set_locale
 
  protected

  def set_locale
    # TODO
    I18n.locale = I18n.default_locale
  end
end
