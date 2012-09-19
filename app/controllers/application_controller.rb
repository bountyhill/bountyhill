class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  before_filter :set_locale

  before_filter :reload_libs if Rails.env.development?
  
  protected
  
  around_filter :setup_access_control

  # enable ActiveRecord::AccessControl
  def setup_access_control(&block)
    # ActiveRecord::AccessControl.as(current_user, &block)
    ActiveRecord::AccessControl.as(User.admin, &block)
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

  # mobile devices: I know it sucks, but in some rare cases we just have
  # to use slightly different markup for mobile and desktop.
  #
  # define the is_mobile_device? method and a few more; 
  # see https://github.com/benlangfeld/mobile-fu
  has_mobile_fu false

  def mobile?
    is_mobile_device? && !is_tablet_device?
  end

  helper_method :mobile?

  #
  # reload code in /lib
  private

  def reload_libs
    Dir["#{Rails.root}/lib/**/*.rb"].each { |path| require_dependency path }
  end

  private

  if Rails.env.development?
    
    around_filter :log_time

    # enable ActiveRecord::AccessControl
    def log_time(&block)
      started_at = Time.now
      yield
    ensure
      Rails.logger.warn "Completed #{request.url} after #{(1000 * (Time.now - started_at)).to_i} msecs."
    end

  end

  private

  def per_page
    12
  end

  around_filter :stat_time
  
  STAT_HAT_ACCOUNT = "eno@open-lab.org"
  
  def stat_hat_queue
    @stat_hat_queue ||= GirlFriday::WorkQueue.new(:stat_hat, :size => 1) do |type, name, value=1|
      expect! type => [ :count, :value ]
      
      case type
      when :count then StatHat::API.ez_post_count(name, STAT_HAT_ACCOUNT, value || 1)
      when :value then StatHat::API.ez_post_value(name, STAT_HAT_ACCOUNT, value)
      end
    end
  end

  # enable ActiveRecord::AccessControl
  def stat_time(&block)
    started_at = Time.now
    yield
  ensure
    stat_hat_queue.push [ :value, "process_time", (1000 * (Time.now - started_at)).to_i ]
  end
end
