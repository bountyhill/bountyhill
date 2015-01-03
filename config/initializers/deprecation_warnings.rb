# encoding: UTF-8

if Rails.env.production? || Rails.env.live? || Rails.env.staging?
  ActiveSupport::Deprecation.silenced = true
end

