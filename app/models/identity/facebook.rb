# encoding: UTF-8

class Identity::Facebook < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.facebook"
  
  # -- Facebook actions ------------------------------------------------
  
  #
  # post a message on user's facebook wall
  def post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    # Side note: put_wall_post posts to user/feeds, which doesn’t include a Share button. 
    # To get one when posting a link, you can use put_connections(user, “links”, details).
    Deferred.facebook("me", "links", self.class.message(text, options[:object]), oauth_hash)
  end
  
  # post a message on bountyhill's facebook wall
  def self.post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }

    # Side note: put_wall_post posts to user/feeds, which doesn’t include a Share button. 
    # To get one when posting a link, you can use put_connections(user, “links”, details).
    Deferred.facebook("me", "links", message(text, options[:object]), oauth_hash)
  end

  private

  #
  # sets up a message hash for a facebook post
  # this message contains the message, a privacy level and if an object is given
  # a name, description, url and an image of that object
  def self.message(text, object=nil)
    msg = { :message => text, :privacy => { 'value' => 'EVERYONE' }}
    
    msg.merge!({
      :name         => object.title,
      :description  => sanitizer.sanitize(object.description, :tags=>[]),
      :link         => (Rails.env.production? ? object.url : 'http://bountyhill.com'),
      :picture      => object.images.first,
    }) if object
    
    msg
  end
  
  #
  # Returns the user's facebook auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :oauth_token      => oauth_token,
      :oauth_expires_at => Time.at(oauth_expires_at)
    }
  end
  
  #
  # Returns the applications's facebook auth as a Hash.
  def self.oauth_hash
    {
      :oauth_token      => Bountybase.config.facebook_app["oauth_token"],
      :oauth_expires_at => nil
    }
  end
end
