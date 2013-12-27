# encoding: UTF-8

class Identity::Google < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.google"
  
  # -- Google actions ------------------------------------------------
  
  #
  # post a message in user's google+ stream
  def post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    # TODO: leverage google clint API here...
    Deferred.google("TODO", self.class.message(text, options[:object]), oauth_hash)
  end

  #
  # post a message in bountyhill's google+ stream
  def self.post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    # TODO: leverage google clint API here...
    Deferred.google("TODO", message(text, options[:object]), oauth_hash)
  end

  private
  
  #
  # sets up a message hash for a google+ post
  def self.message(text, object=nil)
    # TODO: leverage google clint API here...
    msg = { :message => text }
    
    msg.merge!({
      :link         => (Rails.env.production? ? object.url : 'http://bountyhill.com'),
      :name         => object.title,
      :description  => sanitizer.sanitize(object.description, :tags=>[]),
      :picture      => object.images.first,
    }) if object
    
    msg
  end
  
  #
  # Returns the google auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :consumer_key     => consumer_key     || Bountybase.config.google_app["consumer_key"],
      :consumer_secret  => consumer_secret  || Bountybase.config.google_app["consumer_secret"],
      :oauth_token      => oauth_token,
      :oauth_secret     => oauth_secret,
    }
  end
  
  #
  # Returns the applications's google auth as a Hash.
  def self.oauth_hash
    {
      :consumer_key     => Bountybase.config.google_app["consumer_key"],
      :consumer_secret  => Bountybase.config.google_app["consumer_secret"],
      :oauth_token      => Bountybase.config.google_app["oauth_token"],
      :oauth_secret     => Bountybase.config.google_app["oauth_secret"]
    }
  end
end
