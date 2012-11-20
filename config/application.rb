require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

require_relative "../vendor/bountybase/setup"

module Bountyhill
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation can not be found)
    config.i18n.fallbacks = [:en]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.filter_parameters += [:password_confirmation]

    # No timestamped_migrations
    config.active_record.timestamped_migrations = false

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Precompile *all* assets, except those that start with underscore
    config.assets.precompile << /(^[^_\/]|\/[^_])[^\/]*$/

    # -- middleware ---------------------------------------------------

    Dir.glob("#{File.dirname(__FILE__)}/../lib/middleware/*_middleware.rb").sort.each do |file|
      load file
    end

    # Fetch the I18n.locale from the Browser.
    config.middleware.use Rack::Locale
    
    # TwitterAuthMiddleware: handles twitter authentication
    
    # Fetch the twitter configuration from Bountybase.
    config.middleware.use ::TwitterAuthMiddleware, {
      path:             'tw',
      consumer_key:     Bountybase.config.twitter_app["consumer_key"],
      consumer_secret:  Bountybase.config.twitter_app["consumer_secret"],
      redirect_to:      '/sessions/twitter'
    }
    
    # AutoTitleMiddleware: determines the page title from the first <h1> or <h2> 
    config.middleware.use ::AutoTitleMiddleware, :prefix => "Bountyhill"
  end
  
  class Application
    def load_console(app=self)
      r = super
      irbrc = File.join(Rails.root, "config", "irbrc")
      load(irbrc) if File.exists?(irbrc)
      r
    end
  end
end

Money.default_currency = "EUR"

if defined?(SqlLogging)
  SqlLogging::Statistics.show_top_sql_queries = false
end
