# encoding: UTF-8

class Identity::Facebook < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.facebook"
  
  # -- Facebook actions ------------------------------------------------
  
  #
  # post a status
  def update_status(message, object=nil)
    expect! message => String
    expect! object => [nil, Quest]
    
    details = { :message => message, :privacy => { 'value' => 'EVERYONE' }}
    details.merge!({
      :link         => (Rails.env.production? ? object.url : 'http://bountyhill.com'),
      :name         => object.title,
      :description  => sanitizer.sanitize(object.description, :tags=>[]),
      :picture      => object.images.first,
    }) if object
    
    # Side note: put_wall_post posts to user/feeds, which doesn’t include a Share button. 
    # To get one when posting a link, you can use put_connections(user, “links”, details).
    post "me", "links", details
  end

  private
  
  # Returns the facebook auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :oauth_token      => oauth_token,
      :oauth_expires_at => Time.at(oauth_expires_at),
    }
  end

  def post(*args)
    Deferred.facebook *args, oauth_hash
  end
  
end
