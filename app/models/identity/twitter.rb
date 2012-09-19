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
  
  def avatar(opts)
    expect! opts => { :default => [ String, nil ], :size => [ Fixnum, nil ]}

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
end
