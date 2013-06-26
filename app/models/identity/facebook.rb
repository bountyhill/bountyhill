class Identity::Facebook < Identity
  include Identity::Provider
  
  with_metrics! "accounts.facebook"
  
  # -- Facebook actions ------------------------------------------------
  
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
      :oauth_token      => oauth_token,
      :oauth_expires_at => Time.at(oauth_expires_at),
    }
  end

  def facebook(*args)
    Deferred.facebook *args, facebook_auth
  end
  
end
