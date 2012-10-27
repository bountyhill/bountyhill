require "twitter"

class Identity::Twitter < Identity
  # Fix Rails' polymorphic routes
  def self.model_name #:nodoc:
    Identity.model_name
  end

  with_metrics! "accounts.twitter"

  validates :email, presence: true, format: { with: /^[^@]/ }, 
                                   uniqueness: { case_sensitive: false }

  # -- Twitter identity attributes
  
  def screen_name=(screen_name); self.email = screen_name; end
  def screen_name; email; end

  # build the name from the name attribute, fallback to the screen_name
  def name
    name = read_attribute(:name)
    name.blank? ? screen_name : name
  end
  
  
  # Twitter auth tokens
  serialized_attr :oauth_secret, :oauth_token
  attr_accessible :oauth_secret, :oauth_token
  
  # Twitter consumer tokens for admin and hermes user.
  serialized_attr :consumer_key, :consumer_secret
  attr_accessible :consumer_key, :consumer_secret
  
  serialized_attr :info

  # Twitter info record. This entry usually has these keys: 
  # "id", "followers_count", "friends_count", "lang", "location", 
  # "profile_image_url", "profile_image_url_https", "statuses_count"
  def info
    serialized[:info] || {}
  end

  attr_accessible :screen_name, :info, :user, :name, :followed_at, :email
  
  # return the twitter_identity according to the auth hash received
  # from twitter.
  def self.find_or_create(attrs)
    expect! attrs => {
      :screen_name  => String,
      :oauth_token  => String,
      :oauth_secret => String,
      :info         => [Hash, nil],
      :user         => [User, nil]
    }

    user = attrs.delete :user
    name = (attrs[:info] || {}).delete("name")

    transaction do
      user_identity = user.identity(:twitter) if user
      twitter_identity = Identity::Twitter.where(email: attrs[:screen_name]).first

      # What happens if a user signs in via twitter, when he is already 
      # logged in as a user, and the twitter handle exists already in 
      # the database, but belongs to another user? In this case we take
      # away the other user's twitter identity and put it to this user.
      # 
      # This scenario might sound esoteric. A use case, however, is:
      # 
      # - user logs in via its twitter @handle
      # - user logs out
      # - now user registered via "user@email.com" email
      # - user starts or shares a quest. The application asks the user 
      #   to add a twitter login.
      # - user enters his @twitter handle.
      # 
      if twitter_identity && user && twitter_identity.user != user
        # if a twitter identity exists, but belongs to a different user,
        # we "merge" these users.
        twitter_identity.user = user
        twitter_identity.save!
      end
      
      identity = twitter_identity || user_identity || Identity::Twitter.new

      identity.attributes = attrs
      identity.user = user if user
      identity.name = name if name
      identity.save! if identity.changed?
      identity    
    end
  end
  
  def avatar(options)
    expect! options => { :default => [ String, nil ], :size => [ Fixnum, nil ]}

    # url = info["profile_image_url"] # use http URL
    url = info["profile_image_url_https"]
    return options[:default] unless url
    
    url.gsub(/_normal\./, "_reasonably_small.")
  end
  
  # -- Pseudo attributes ----------------------------------------------

  attr :follow_bountyhermes, true
  attr_accessible :follow_bountyhermes

  # -- Twitter actions ------------------------------------------------

  # This method makes the user follow @bountyhermes. If the user followed
  # @bountyhermes before, this method is a no-op.
  def follow
    follow! unless followed_at?
  end
  
  def follow!
    followee = Bountybase.config.twitter_notifications["user"]
    expect! followee => /^[^@]/
  
    twitter :follow, followee
    update_attributes :followed_at => Time.now
    true
  end

  #
  # retweet a status
  def update_status(msg)
    twitter :update, msg
  end
  
  #
  # Send a direct message *to this user*. Note that 
  def direct_message(msg)
    hermes = User.hermes.identity(:twitter)
    hermes.send :twitter, :direct_message_create, email, msg
  end
  
  private
  
  # Returns the twitter auth as a Hash. While one might be tempted to 
  # just use the Identity::Twitter object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def twitter_auth
    oauth = {
      consumer_secret:    consumer_secret, 
      consumer_key:       consumer_key, 
      oauth_token:        oauth_token,
      oauth_token_secret: oauth_secret
    }

    oauth[:consumer_secret] ||= User.admin.identity(:twitter).consumer_secret
    oauth[:consumer_key] ||= User.admin.identity(:twitter).consumer_key
    
    oauth
  end
  
  def twitter(*args)
    Deferred.twitter *args, twitter_auth
  end
end
