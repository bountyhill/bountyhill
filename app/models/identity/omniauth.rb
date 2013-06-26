module Identity::Omniauth
  # can be used by identity models that are handled by omniauth
  # e.g.
  # class Identity::Twitter
  #   include ::Identitiy::Omniauth
  # end

  # Info attributes derived from auth hash schema - see: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
  unless const_defined?(:INFO_ATTRIBUTES)
    const_set(:INFO_ATTRIBUTES, %w(nickname first_name last_name location description image phone))
  end

  def self.included(base)
    base.send :include, InstanceMethods
    base.send :extend,  ClassMethods
  end

  module ClassMethods
    def self.extended(base)
      base.class_eval do
        # Fix Rails' polymorphic routes
        def self.model_name #:nodoc:
          Identity.model_name
        end
                
        # OAuth tokens and info
        serialized_attr :oauth_secret, :oauth_token, :oauth_expires_at, :info
        attr_accessible :oauth_secret, :oauth_token, :oauth_expires_at, :info
        
        attr_accessible :identifier, :name, :email
        
        # stores user's identifier
        validates :identifier, :presence => true, :format => { :with => /^[^@]/ }, :uniqueness => { :case_sensitive => false }
      end
    end
    
    # return the identity according to the auth-attributes received from provider
    # or create a new identity object of the actual identifiy class
    def find_or_create(identifier, user = nil, attrs_hash = {})
      expect! identifier  => [String, nil]
      expect! user        => [User, nil]
      expect! attrs_hash  => Hash

      W "Oauth Attributes Hash", attrs_hash
      
      provider = self.name.split("::").last.underscore.to_sym
      
      unless (expected_provider = attrs_hash['provider'].to_sym) == provider
        raise "Wrong provider - actual: #{provider} vs. expected: #{expected_provider}"
      end
      
      transaction do
        user_identity     = user.identity(provider) if user
        current_identity  = self.where(:identifier => identifier).first

        # What happens if a user signs in via a provider, when he is already 
        # logged in as a user, and the provider's identifier exists already in 
        # the database, but belongs to another user? In this case we take
        # away the other user's identity and put it to this user.
        # 
        # This scenario might sound esoteric. A use case, however, is:
        # 
        # - user logs in via its provider's identifier
        # - user logs out
        # - now user registered via "user@email.com" email
        # - user starts or shares a quest. The application asks the user
        # to add a provider login.
        # - user enters his provider's identifier.
        # 
      
        # if an identity of the same provider exists, but belongs to a different user, we "merge" these users.
        # TODO: we have to move all objects belonging to the user to the new user as well
        if current_identity && user && current_identity.user != user
          current_identity.user = user
          current_identity.save!
        end
      
        attrs_info  = attrs_hash["info"]        || {}
        attrs_creds = attrs_hash["credentials"] || {}
        identity    = current_identity || user_identity || self.new
        
        # set basics
        identity.user       ||= user
        identity.identifier = identifier
        identity.info       = attrs_info
        
        # TODO: these attributes could be serialized to
        identity.name       = attrs_info["name"]  if attrs_info["name"]
        identity.email      = attrs_info["email"] if attrs_info["email"]
        
        # set credentials
        identity.oauth_token      = attrs_creds["token"]                if attrs_creds["token"]
        identity.oauth_secret     = attrs_creds["secret"]               if attrs_creds["secret"]
        identity.oauth_expires_at = Time.at(attrs_creds["expires_at"])  if attrs_creds["expires_at"]
        
        # TODO: when a serialized attribute changes e.g. oauth_expires_at, it will not be deteced by indentity.changed?
        identity.save! if identity.changed?
        identity
      end
    end
  end

  module InstanceMethods
  
    Identity::Omniauth::INFO_ATTRIBUTES.each do |info_attribute|
      define_method(info_attribute) do
        (info || {})[info_attribute]
      end
    end

    def avatar(options={})
      expect! options => { 
        :default  => [ String, nil ],
        :size     => [ Fixnum, nil ]
      }
    
      image || options[:default]
    end
  
  end
end
