# encoding: UTF-8

OmniAuth.config.logger      = Rails.logger
OmniAuth.config.on_failure  = IdentitiesController.action(:failure)
OmniAuth.config.test_mode   = Rails.env.test?

# OmniAuthMiddleware: handles facebook authentication

# Fetch the providers configuration from Bountybase.
Rails.application.config.middleware.use OmniAuth::Builder do

  provider :twitter, Bountybase.config.twitter_app["consumer_key"], Bountybase.config.twitter_app["consumer_secret"]
  
  provider :facebook, Bountybase.config.facebook_app["consumer_key"], Bountybase.config.facebook_app["consumer_secret"], {
    :scope  => 'email, publish_stream' }
    
  # for configuration options see: https://github.com/zquestz/omniauth-google-oauth2
  # does not provide the necessary access rights to insert moments via google+ API although 
  # claimed here to be working: https://github.com/zquestz/omniauth-google-oauth2/issues/67
  provider :google_oauth2, Bountybase.config.google_app["consumer_key"], Bountybase.config.google_app["consumer_secret"], {
    :name                     => 'google',
    :scope                    => 'userinfo.email, userinfo.profile, plus.login', #plus.me
    :request_visible_actions  => Bountybase.config.google_app["activity"],
    :access_type              => 'offline'
   }
  
  provider :linked_in, Bountybase.config.linkedin_app["consumer_key"], Bountybase.config.linkedin_app["consumer_secret"], {
    :name   => 'linkedin',
    :scope  => 'r_basicprofile r_emailaddress rw_nus' }

  provider :xing, Bountybase.config.xing_app["consumer_key"], Bountybase.config.xing_app["consumer_secret"]
end
