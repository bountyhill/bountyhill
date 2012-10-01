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
  
  # Twitter auth tokens
  serialized_attr :oauth_secret, :oauth_token
  serialized_attr :info

  # Twitter info record. This entry usually has these keys: 
  # "id", "followers_count", "friends_count", "lang", "location", 
  # "profile_image_url", "profile_image_url_https", "statuses_count"
  def info
    serialized[:info] || {}
  end

  attr_accessible :screen_name, :oauth_secret, :oauth_token, :info, :user, :name, :followed_at, :email
  
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
    info["profile_image_url"] || options[:default]
  end
  
  # -- Pseudo attributes ----------------------------------------------

  attr :follow_bountyhill, true
  attr_accessible :follow_bountyhill

  # -- Twitter actions ------------------------------------------------

  # This method makes the user follow @bountyhill. If the user followed
  # @bountyhill before, this method is a no-op.
  def follow
    follow! unless followed_at?
  end
  
  def follow!
    followee = Bountybase.config.twitter_app["user"]
    expect! followee => /^[^@]/
  
    twitter :follow, followee
    update_attributes :followed_at => Time.now
  end

  #
  # retweet a status
  def update_status(msg)
    twitter :update, msg
  end
  
  private
  
  def twitter(*args)
    Deferred.twitter *args, oauth_token: oauth_token,
                            oauth_secret: oauth_secret
  end
end
