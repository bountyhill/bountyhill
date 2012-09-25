class ApplicationController < ActionController::Base
  protect_from_forgery
  include ApplicationController::Halt
  include ApplicationController::Sessions
  include ApplicationController::RequiredIdentity
  include ApplicationController::Debugging

  private
  
  # -- ActiveRecord::AccessControl ------------------------------------

  around_filter :setup_access_control
  
  def setup_access_control(&block)
    ActiveRecord.as(current_user, &block)
  end

  # The locale is already set by a Rack::Locale middle-ware. See:  
  # https://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/locale.rb
  #
  # before_filter :set_locale
  # def set_locale
  #   raise I18n.locale.inspect
  #   # I18n.locale = I18n.default_locale
  # end

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
    24
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

  before_filter do |controller|
    lines = session.each do |k,v| 
      controller.debug k, v unless k.in?(%w(_csrf_token))
    end
    
    controller.debug "User", "User.find(#{current_user.id})"
  end

  # -- the confirmation reminder
  
  before_filter :show_confirmation_reminder
  
  def hide_confirmation_reminder
    @confirmation_reminder_hidden = true
  end
  
  def show_confirmation_reminder
    return if @confirmation_reminder_hidden
    return unless current_user && (email = current_user.identity(:email)) && !email.confirmed?

    flash.now[:warn] = render_to_string(:partial => "shared/confirmation_reminder").html_safe
  end
end
