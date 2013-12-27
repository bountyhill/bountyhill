# encoding: UTF-8

require "twitter"

class Identity::Twitter < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.twitter"
  
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
  
    Deferred.twitter(:follow, followee, oauth_hash)
    update_attributes :followed_at => Time.now
    true
  end

  #
  # post a tweet in user's twitter feed
  def post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    Deferred.twitter(:update, self.class.message(text, options[:object]), oauth_hash)
  end
  
  #
  # post a tweet in bountyhill's twitter feed
  def self.post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    Deferred.twitter(:update, message(text, options[:object]), oauth_hash)
  end
  
  #
  # Send a direct message *to this user*.
  def direct_message(msg)
    hermes = User.hermes.identity(:twitter)
    Deferred.twitter(:direct_message_create, handle, msg, hermes.send(:oauth_hash))
  end
  
  private
  
  #
  # sets up a message text for a tweet
  def self.message(text, object=nil)
    object.present? ? "#{text} #{object.url}" : text
  end
  
  #
  # Returns the twitter auth as a Hash. While one might be tempted to 
  # just use the Identity::Twitter object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :consumer_key       => consumer_key     || Bountybase.config.twitter_app["consumer_key"],
      :consumer_secret    => consumer_secret  || Bountybase.config.twitter_app["consumer_secret"],
      :oauth_token        => oauth_token,
      :oauth_token_secret => oauth_secret
    }
  end
  
  #
  # Returns the applications's twitter auth as a Hash.
  def self.oauth_hash
    {
      :consumer_key       => Bountybase.config.twitter_app["consumer_key"],
      :consumer_secret    => Bountybase.config.twitter_app["consumer_secret"],
      :oauth_token        => Bountybase.config.twitter_app["oauth_token"],
      :oauth_token_secret => Bountybase.config.twitter_app["oauth_secret"]
    }
  end
end
