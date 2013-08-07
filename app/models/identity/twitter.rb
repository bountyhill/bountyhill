# encoding: UTF-8

require "twitter"

class Identity::Twitter < Identity
  include Identity::Provider
  
  with_metrics! "accounts.twitter"
  
  # Twitter consumer tokens for admin and hermes user.
  serialized_attr :consumer_key, :consumer_secret
  attr_accessible :consumer_key, :consumer_secret
  
  attr_accessible :followed_at

  # -- Pseudo attributes ----------------------------------------------

  attr :follow_bountyhermes, true
  attr_accessible :follow_bountyhermes

  def handle
    nickname
  end
  alias_method :screen_name, :handle

  # -- Twitter actions ------------------------------------------------

  # This method makes the user follow @bountyhermes. If the user followed
  # @bountyhermes before, this method is a no-op, and the method returns
  # false. 
  def follow
    return false if followed_at?
    follow!
    return true
  end
  
  def follow!
    followee = Bountybase.config.twitter_notifications["user"]
    expect! followee => /^[^@]/
  
    post :follow, followee
    update_attributes :followed_at => Time.now
    true
  end

  #
  # retweet a status
  def update_status(msg)
    post :update, msg
  end
  
  #
  # Send a direct message *to this user*. Note that 
  def direct_message(msg)
    hermes = User.hermes.identity(:twitter)
    hermes.send :post, :direct_message_create, handle, msg
  end
  
  private
  
  # Returns the twitter auth as a Hash. While one might be tempted to 
  # just use the Identity::Twitter object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    oauth = {
      :consumer_secret  => consumer_secret,
      :consumer_key     => consumer_key,
      :oauth_token      => oauth_token,
      :oauth_secret     => oauth_secret
    }

    oauth[:consumer_secret] ||= User.admin.identity(:twitter).consumer_secret
    oauth[:consumer_key]    ||= User.admin.identity(:twitter).consumer_key
    
    oauth
  end
  
  def post(*args)
    Deferred.twitter *args, oauth_hash
  end
end
