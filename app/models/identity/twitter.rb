class Identity::Twitter < Identity
  # Fix Rails' polymorphic routes
  def self.model_name #:nodoc:
    Identity.model_name
  end
  
  # -- Twitter identity attributes
  
  def screen_name
    read_attribute :name
  end

  def name
    name = read_attribute(:name)
    return if name.blank?
    "@#{name}"
  end

  def screen_name=(screen_name)
    write_attribute :name, screen_name
  end

  serialized_attr :access_secret, :access_token

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
end
