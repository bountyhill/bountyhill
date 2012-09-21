require "twitter"

class Identity::Twitter < Identity
  # Fix Rails' polymorphic routes
  def self.model_name #:nodoc:
    Identity.model_name
  end

  validates :name, presence: true, format: { with: /^[^@]/ }, 
                                   uniqueness: { case_sensitive: false }

  # -- Twitter identity attributes
  
  def screen_name
    "@#{name}"
  end

  serialized_attr :oauth_secret, :oauth_token

  def update_auth!(auth)
    return if oauth_token == auth[:oauth_token] && oauth_secret == auth[:oauth_secret]

    self.oauth_token = auth[:oauth_token]
    self.oauth_secret = auth[:oauth_secret]
    
    update_attributes! :oauth_token => auth[:oauth_token],
      :oauth_secret => auth[:oauth_secret]
  end

  #
  
  def avatar(options)
    expect! options => { :default => [ String, nil ], :size => [ Fixnum, nil ]}

    unless options[:avatar]
      options[:avatar] = fetch_avatar_url
      save!
    end

    return options[:avatar]
  end
  
  def fetch_avatar_url(size = "bigger")
    url = "https://api.twitter.com/1/users/profile_image?screen_name=#{screen_name}&size=#{size}"
    Bountybase::HTTP.resolve url
  end

  # -- Twitter actions ------------------------------------------------

  # The follow_bountyhill pseudo attribute exists only for
  # the login via twitter form.
  attr :follow_bountyhill, true
  
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
                            oauth_token_secret: oauth_secret
  end
end
