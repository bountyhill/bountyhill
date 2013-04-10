class Identity::Facebook < Identity
  # Fix Rails' polymorphic routes
  def self.model_name #:nodoc:
    Identity.model_name
  end
  
  with_metrics! "accounts.facebook"

  # stores user's facebook uid
  validates :email, presence: true, format: { with: /^[^@]/ }, 
                                   uniqueness: { case_sensitive: false }

  # -- Facebook identity attributes

  def uid=(uid); self.email = uid; end
  def uid; email; end

  
  # Facebook auth tokens
  serialized_attr :oauth_token, :oauth_expires_at
  attr_accessible :oauth_token, :oauth_expires_at
  
  serialized_attr :info
  
  # Facebook info record. This entry usually has these keys: 
  # :nickname   => 'jbloggs',
  # :email      => 'joe@bloggs.com',
  # :name       => 'Joe Bloggs',
  # :first_name => 'Joe',
  # :last_name  => 'Bloggs',
  # :image      => 'http://graph.facebook.com/1234567/picture?type=square',
  # :urls       => { :Facebook => 'http://www.facebook.com/jbloggs' },
  # :location   => 'Palo Alto, California',
  # :verified   => true
  def info
    serialized[:info] || {}
  end

  attr_accessible :uid, :info, :user, :name, :email
  
  # return the facebook_identity according to the auth hash received
  # from facebook.
  def self.find_or_create(attrs)
    expect! attrs => {
      :uid              => String,
      :oauth_token      => String,
      :oauth_expires_at => Time,
      :info             => [Hash, nil],
      :user             => [User, nil]
    }

    user = attrs.delete :user
    name = (attrs[:info] || {}).delete("name")

    transaction do
      user_identity = user.identity(:facebook) if user
      facebook_identity = Identity::Facebook.where(email: attrs[:uid]).first

      # What happens if a user signs in via facebook, when he is already 
      # logged in as a user, and the facebook uid exists already in 
      # the database, but belongs to another user? In this case we take
      # away the other user's facebook identity and put it to this user.
      # 
      # This scenario might sound esoteric. A use case, however, is:
      # 
      # - user logs in via its facebook uid
      # - user logs out
      # - now user registered via "user@email.com" email
      # - user starts or shares a quest. The application asks the user 
      #   to add a facebook login.
      # - user enters his facebook uid.
      # 
      if facebook_identity && user && facebook_identity.user != user
        # if a facebook identity exists, but belongs to a different user,
        # we "merge" these users.
        facebook_identity.user = user
        facebook_identity.save!
      end
      
      identity = facebook_identity || user_identity || Identity::Facebook.new

      identity.attributes = attrs
      identity.user = user if user
      identity.name = name if name
      identity.save! if identity.changed?
      identity
    end
  end
  
  def description
    # TODO
    # info["description"]
  end

  def nickname
    info["nickname"]
  end
  
  def avatar(options={})
    expect! options => { :default => [ String, nil ], :size => [ Fixnum, nil ]}

    info["image"] || options[:default]
  end
  
  #
  # post a status
  def update_status(msg)
    facebook "me", "feed", :message => msg
  end

  private
  
  # Returns the facebook auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def facebook_auth
    {
      oauth_token:      oauth_token,
      oauth_expires_at: oauth_expires_at,
    }
  end

  def facebook(*args)
    Deferred.facebook *args, facebook_auth
  end
  
end
