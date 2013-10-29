# encoding: UTF-8

require 'linkedin'

class Identity::Linkedin < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.linkedin"

  #
  # post a status
  def update_status(msg)
    post :add_share, :comment => msg
  end

  private
  
  # Returns the linkedin auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :consumer_key       => consumer_key     || Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret    => consumer_secret  || Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token        => oauth_token,
      :oauth_token_secret => oauth_secret
    }
  end

  def post(*args)
    Deferred.linkedin *args, oauth_hash
  end
  
end
