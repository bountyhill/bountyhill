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

  private
  
  #
  # Change the layout used for the current action. We support these layouts:
  #
  # - "application" the default application layout
  # - "static" wraps a single, 12 column spanning row into the "application" layout.
  #   This is useful for single pages, probably created from markdown.
  #
  def set_layout(layout)
    @layout = layout.to_s
  end
  
  def layout #:nodoc:
    @layout || "application"
  end
  
  layout :layout
end
