# encoding: UTF-8

class Identity::Google < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.google"
  
  # -- Google actions ------------------------------------------------
  
  #
  # post a status
  def update_status(message, object=nil)
    expect! message => String
    expect! object => [nil, Quest]
    
    # TODO: leverage google clint API here...
    post "TODO", :message => message
    
  end

  private
  
  # Returns the google auth as a Hash. While one might be tempted to
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
    Deferred.google *args, oauth_hash
  end
  
end
