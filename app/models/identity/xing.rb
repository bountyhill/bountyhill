# encoding: UTF-8

require 'xing'

class Identity::Xing < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.xing"

  #
  # post a status
  def update_status(message, object=nil)
    expect! message => String
    expect! object => [nil, Quest]
    
    message += " #{object.url}" if object
    
    Deferred.xing :create_status_message, message, oauth_hash
  end

  private
  
  # Returns the xing auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :consumer_key       => consumer_key     || Bountybase.config.xing_app["consumer_key"],
      :consumer_secret    => consumer_secret  || Bountybase.config.xing_app["consumer_secret"],
      :oauth_token        => oauth_token,
      :oauth_token_secret => oauth_secret
    }
  end

  def post(*args)
    Deferred.xing *args, oauth_hash
  end

end
