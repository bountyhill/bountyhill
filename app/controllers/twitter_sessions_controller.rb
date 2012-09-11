#
# The TwitterSessionsController initiates a twitter signup and potentially
# adds a twitter account as a follower. It is a front for the 
# TwitterAuthMiddleware.
#
# The TwitterAuthMiddleware intercepts "/tw/" URLs. The "/tw/login" URL
# sets up and redirects to twitter auth. When Twitter oauth returns to 
# TwitterAuthMiddleware, which then redirects to either `twitter_sessions/created`
# or `twitter_sessions/failed.`
#
class TwitterSessionsController < ApplicationController
  def create
    # the create method receives the sessions/by_twitter form (which
    # basically creates just a "yes, I want to follow" checkbox.)
    #
    # We store the form data in the session, to be evaluated during "created".
    # sessions[:follow_me] = true
    
    # Where to go back? If the request has a "target" parameter, this is
    # where we'll go.
    if params[:target]
      session[:target] = params[:target]
    end
    
    redirect_to "/tw/login"
  end
  
  # The created action is where the TwitterAuthMiddleware will redirect to
  # after the user logged in successfully.
  def created
    # At this point an existing user might have signed in for the first time,
    # or might just revisit the site. In the latter case we don't produce a flash message.
    if Time.now - current_user.created_at < 5
      flash[:success] = "twitter_sessions.success".t
    end
    
    if session.delete(:follow_me)
      # follow_me
      flash[:success] = "twitter_sessions.following".t
    end
    
    redirect_to_target
  end
  
  # The failed action is where the TwitterAuthMiddleware will redirect to
  # after the user cancelled log in.
  def failed
    session.delete(:follow_me)
    redirect_to_target
  end

  private
  
  def redirect_to_target
    target = session.delete(:target) || "/"
    redirect_to target
  end
  
end
