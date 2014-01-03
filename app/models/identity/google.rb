# encoding: UTF-8

require 'google/api_client'

class Identity::Google < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.google"
  
  #
  # consider Google API as accessible as long as an refresh token is present since
  # this token is used to get a new and valid token before each an every API call of the user
  def api_accessible?
    oauth_refresh_token.present?
  end

  # -- Google actions ------------------------------------------------
  
  #
  # post a message in user's google+ stream
  # is curently not supported by google 
  # the only alterantive is to record a moment for the user - see: https://developers.google.com/+/api/latest/moments/insert
  # PLs. note that there are problems getting the correct access token for insterting moments via the google_oauth2 provider
  def post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    Deferred.google({
      :api_method   => self.class.plus.moments.insert,
      :body_object  => self.class.message(text, options[:object]),
      :parameters   => { :collection => 'vault', :userId => 'me' }
    }, oauth_hash)
  end

  #
  # post a message in bountyhill's google+ stream
  # to get access to google's page API we have to apply for a
  # partnership - see: https://developers.google.com/+/api/pages-signup
  def self.post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    # TODO: leverage google clint API here...
    #Deferred.google(message(text, options[:object]), oauth_hash)
    return
  end

  private
  
  def self.plus
    @@plus ||= ::Google::APIClient.new(
      :application_name => Bountybase.config.google_app["name"],
      :application_version => "1.0").discovered_api('plus')
  end
  
  #
  # sets up a message hash for a google+ post
  # see: https://developers.google.com/+/api/latest/moments#resource
  def self.message(text, object=nil)
    rand_id = Time.now.to_i.to_s
    msg     = {
      :kind   => "plus#moment",
      :type   => Bountybase.config.google_app["activity"],
      :debug  => Rails.env.development?,
      :target => {
        :kind       => "plus#itemScope",
        :id         => rand_id,
        :name       => text
      }
    }
    
    # add object's description
    msg[:target].merge!({:description => sanitizer.sanitize(object.description, :tags=>[]) }) if object
    
    # add object's main image
    msg[:target].merge!({ :image => object.images.first.to_s }) if object && object.images.first
    
    # there is only an either or approach for creating an activity possible - either provide an url 
    # with (microdata-enriched) of the target page or provide descriptive elements - see:
    # http://gusclass.com/blog/2013/05/16/passive-sharing-writing-app-activities-without-target-urls/
    msg[:target] = { :url => object.url } if object && Rails.env.production?
    
    msg
  end
  
  #
  # Returns the google auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :consumer_key         => consumer_key     || Bountybase.config.google_app["consumer_key"],
      :consumer_secret      => consumer_secret  || Bountybase.config.google_app["consumer_secret"],
      :oauth_refresh_token  => oauth_refresh_token,
      :oauth_expires_at     => oauth_expires_at
    }
  end
  
  #
  # Returns the applications's google auth as a Hash.
  def self.oauth_hash
    {
      :consumer_key         => Bountybase.config.google_app["consumer_key"],
      :consumer_secret      => Bountybase.config.google_app["consumer_secret"],
      :oauth_refresh_token  => Bountybase.config.google_app["oauth_refresh_token"],
      :oauth_expires_at     => nil
    }
  end
end
