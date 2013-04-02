OmniAuth.config.logger = Rails.logger

# OmniAuthMiddleware: handles facebook authentication

# Fetch the facebook configuration from Bountybase.
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, Bountybase.config.facebook_app["app_id"], Bountybase.config.facebook_app["app_secret"]
end
