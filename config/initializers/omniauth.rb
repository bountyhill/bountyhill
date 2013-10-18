# encoding: UTF-8

OmniAuth.config.logger      = Rails.logger
OmniAuth.config.on_failure  = IdentitiesController.action(:failure)
OmniAuth.config.test_mode   = Rails.env.test?

# OmniAuthMiddleware: handles facebook authentication

# Fetch the providers configuration from Bountybase.
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter,        Bountybase.config.twitter_app["consumer_key"],      Bountybase.config.twitter_app["consumer_secret"]
  provider :facebook,       Bountybase.config.facebook_app["consumer_key"],     Bountybase.config.facebook_app["consumer_secret"],    :scope => 'email, publish_stream'
  # provider :linked_in,      Bountybase.config.linked_in_app["consumer_key"],    Bountybase.config.linked_in_app["consumer_secret"],   :scope => 'r_basicprofile r_emailaddress'
  # provider :google_oauth2,  Bountybase.config.google_plus_app["consumer_key"],  Bountybase.config.google_plus_app["consumer_secret"], :access_type => 'offline', :approval_prompt => ''
end
