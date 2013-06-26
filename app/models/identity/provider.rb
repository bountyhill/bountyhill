module Identity::Provider
  # can be used by identity models that are handled by omniauth
  # e.g.
  # class Identity::Twitter
  #   include ::Identitiy::Provider
  # end

  # Info attributes derived from auth hash schema - see: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
  const_set(:INFO_ATTRIBUTES, %w(name email nickname first_name last_name location description image phone)) unless const_defined?(:INFO_ATTRIBUTES)

  # Credential attributes derived from auth hash schema - see: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
  const_set(:CREDENTIAL_ATTRIBUTES, %w(secret token expires_at)) unless const_defined?(:CREDENTIAL_ATTRIBUTES)

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
                
        serialized_attr :credentials, :info
        attr_accessible :credentials, :info, :identifier, :name, :email
        
        # validates user's provider's identifier
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
      
        identity = current_identity || user_identity || self.new
        
        identity.user       ||= user
        identity.identifier   = identifier
        identity.info         = attrs_hash["info"]        || {}
        identity.credentials  = attrs_hash["credentials"] || {}
        
        identity.save! if identity.changed?
        identity
      end
    end
  end

  module InstanceMethods
  
    Identity::Provider::INFO_ATTRIBUTES.each do |info_attribute|
      define_method(info_attribute) do
        hash = (info || {}).with_indifferent_access
        hash[info_attribute]
      end
    end

    Identity::Provider::CREDENTIAL_ATTRIBUTES.each do |credential_attribute|
      define_method("oauth_#{credential_attribute}") do
        hash = (credentials || {}).with_indifferent_access
        hash[credential_attribute]
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
