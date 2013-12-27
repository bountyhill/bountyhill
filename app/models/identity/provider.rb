# encoding: UTF-8

require 'html/sanitizer'

module Identity::Provider
  # can be used by identity models that are handled by omniauth
  # e.g.
  # class Identity::Twitter
  #   include ::Identitiy::Provider
  # end

  # Info attributes derived from auth hash schema - see: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
  const_set(:INFO_ATTRIBUTES, %w(name email nickname first_name last_name location description image phone urls)) unless const_defined?(:INFO_ATTRIBUTES)

  # Credential attributes derived from auth hash schema - see: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
  const_set(:CREDENTIAL_ATTRIBUTES, %w(secret token expires expires_at)) unless const_defined?(:CREDENTIAL_ATTRIBUTES)

  def self.included(base)
    base.send :include, InstanceMethods
    base.send :extend,  ClassMethods
  end

  module ClassMethods
    def self.extended(base)
      base.class_eval do
        # information returned by oauth
        serialized_attr :info, :credentials, :extra
        attr_accessible :info, :credentials, :extra, :identifier, :name, :email, :location
        
        # consumer tokens for admin and hermes user.
        serialized_attr :consumer_key, :consumer_secret
        attr_accessible :consumer_key, :consumer_secret
        
        # validates user's provider's identifier
        validates :identifier, :presence => true, :format => { :with => /^[^@]/ }, :uniqueness => { :case_sensitive => false }
        
        before_create :save_email
      end
    end

    # provide own HTML sanitizer
    def sanitizer
      @@sanitizer ||= HTML::FullSanitizer.new
    end
    
    # return application's oauth hash
    def oauth_hash
      raise "This method has to be provided by the social identity provider class!"
    end
        
    # return the identity according to the auth-attributes received from provider
    # or create a new identity object of the actual identifiy class
    def find_or_create(identifier, user = nil, attrs_hash = {})
      expect! identifier  => [String, nil]
      expect! user        => [User, nil]
      expect! attrs_hash  => Hash

      attrs_hash = attrs_hash.with_indifferent_access
      W("Oauth Attributes Hash", attrs_hash) unless Rails.env.test?
      
      provider = self.name.split("::").last.underscore
      if (expected = attrs_hash[:provider]).present? && expected.to_s != provider
        raise "Wrong provider - actual: #{provider} vs. expected: #{expected}"
      end
      
      transaction do
        user_identity       = user.identity(provider.to_sym) if user
        identified_identity = self.where(:identifier => identifier).first

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
        # - user starts or shares a quest. The application asks the user to add a provider login.
        # - user enters his provider's identifier.
        # 
      
        # if an identity of the same provider exists, but belongs to a different user, we "merge" these users.
        # TODO: we have to move all objects belonging to the user to the new user as well and soft_delete the old one afterwards
        if identified_identity && user && identified_identity.user != user
          identified_identity.user = user
          identified_identity.save!
        end
      
        # init identity either from identity with the same identifier or
        # with the identity of the given user or
        # with a new instance of the actual identity class
        identity = identified_identity || user_identity || self.new
        
        # init or update identity attributes
        identity.identifier   = identifier
        identity.credentials  = attrs_hash["credentials"] || {}
        identity.info         = attrs_hash["info"]        || {}
        identity.extra        = attrs_hash["extra"]       || {}
        
        # set user of identity if none is present already (if an identity for the given identifier was found)
        # to either a user with an identity with the same email or the given user (current_user)
        identity.user ||=  (identified_identity && identified_identity.user) || Identity.find_user(identity.info) || user
        
        # Note: changes in serialized attributes are not detected by identity.changed?
        identity.save! #if identity.changed?
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
    
    def sanitizer
      self.class.sanitizer
    end
    
    private 
    
    # set email attribute from info hash
    def save_email
      self.email = email
    end
    
    # return user's oauth hash
    def oauth_hash
      raise "This method has to be provided by the social identity provider instance!"
    end

    # sets up a message hash or string for a post in a social media network
    def message
      raise "This method has to be provided by the social identity provider instance!"
    end
  end
end
