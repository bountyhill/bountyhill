if Rails.env.production? || Rails.env.staging?
  ActiveSupport::Deprecation.silenced = true
end

