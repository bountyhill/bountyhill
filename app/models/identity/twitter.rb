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

    # find existing identity from current_user
    identity = if user
      user.identity(:twitter)
    else
      Identity::Twitter.where(:email => attrs[:screen_name]).first
    end

    identity ||= Identity::Twitter.new
    
    identity.attributes = attrs
    identity.user = user if user
    identity.name = name if name
    identity.save! if identity.changed?
    identity
  end
  
  def avatar(options)
    expect! options => { :default => [ String, nil ], :size => [ Fixnum, nil ]}
    info["profile_image_url"] || options[:default]
  end
  

  # -- Twitter actions ------------------------------------------------

  # The follow_bountyhill pseudo attribute exists only for
  # the login via twitter form.
  attr :follow_bountyhill, true
  attr_accessible :follow_bountyhill
  
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

  private
  
  def twitter(*args)
    Deferred.twitter *args, oauth_token: oauth_token,
                            oauth_secret: oauth_secret
  end
end
