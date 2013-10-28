# encoding: UTF-8

class Identity::Linkedin < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.linkedin"
  
  # -- Linkedin actions ------------------------------------------------
  
  #
  # post a status
  def update_status(msg)
    # TODO: leverage linkedin clint API here...
    post "TODO", :message => msg
    
  end

  private
  
  # Returns the linkedin auth as a Hash. While one might be tempted to
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
    Deferred.linkedin *args, oauth_hash
  end
  
end
