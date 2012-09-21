class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  private
  
  # -- ActiveRecord::AccessControl ------------------------------------

  around_filter :setup_access_control
  
  def setup_access_control(&block)
    ActiveRecord::AccessControl.as(current_user, &block)
  end

  # The locale is already set by a Rack::Locale middle-ware. See:  
  # https://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/locale.rb
  #
  # before_filter :set_locale
  # def set_locale
  #   raise I18n.locale.inspect
  #   # I18n.locale = I18n.default_locale
  # end

  # -- Adjust the layout ----------------------------------------------
  #
  # We support these layouts:
  #
  # - "application" the default application layout
  # - "static" wraps a single, 12 column spanning row into the 
  #   "application" layout. This is useful for single pages, probably 
  #   created from markdown.
  #
  def set_layout(layout)
    @layout = layout.to_s
  end
  
  def layout #:nodoc:
    @layout || "application"
  end
  
  layout :layout

  # -- Detect mobile devices  -----------------------------------------
  #
  # I know it sucks, but in some rare cases we just have to render
  # a slightly different markup for mobile.
  #
  # has_mobile_fu defines the is_mobile_device? method and a few more; 
  # see https://github.com/benlangfeld/mobile-fu
  #
  has_mobile_fu false

  # return true if this is a mobile *phone*
  def mobile?
    is_mobile_device? && !is_tablet_device?
  end

  helper_method :mobile?

  # -- Reload code in /lib on each request ----------------------------
  #
  # This was the default behaviour in Rails 2; Rails 3 only reloads
  # code in /app.
  #
  def reload_libs
    Dir["#{Rails.root}/lib/**/*.rb"].each { |path| require_dependency path }
  end
  
  before_filter :reload_libs if Rails.env.development?

  # -- The default number of items per page in a will_paginate enumeration.
  #
  def per_page
    12
  end

  # -- default_url_options --------------------------------------------
  #
  # This sets and keeps the default_url_options. It assumes that all 
  # requests run from the same domain; you cannot generate links to 
  # multiple domains with this. Consequently the before_filter should
  # run only once - but there is apparently no way to remove a
  # before_filter.
  #
  before_filter :set_mailer_default_url_options
  
  def set_mailer_default_url_options
    @@default_url_options ||= begin
      { 
        :host => request.host_with_port,
        :protocol => request.scheme
      }.tap do |options|
        ActionMailer::Base.default_url_options = options.dup
        DeferredAction.default_url_options = options.dup
      end
    end
  end
  
  # -- count requests, measure process time ---------------------------
  # 
  # Create events to a) measure request time and b) count requests.
  #
  around_filter :stat_time

  def stat_time(&block)
    started_at = Time.now
    yield
  ensure
    msecs = (1000 * (Time.now - started_at)).to_i
    
    Bountybase.metrics.request!
    Bountybase.metrics.pageview msecs
    
    if Rails.env.development?
      Rails.logger.warn "Completed #{request.url} after #{msecs} msecs."
    end
  end

  # -- debugging ------------------------------------------------------
  #
  # Keep the value of the incoming session. It then can be displayed in
  # the application layout. To disable just dactivate the before_filter.

  # before_filter :keep_session
  
  def keep_session
    @debug_output = session.inspect
  end
end
