class SessionsController < ApplicationController
  skip_before_filter :show_confirmation_reminder

  # This action renders signin forms. 
  #
  # The "req" parameter determines which forms to show:
  #
  # - "email": show email signin form, when not logged in; show email
  #   signup form, when logged in, but no email identity is present.
  # - "twitter": show twitter signin form.
  # - "confirmed": show email signin form, when not logged in; show email
  #   signup form, when logged in, but no email identity is present.
  #   show "confirmed" when email identity is present but not confirmed.
  # - all other values: show "email" and "twitter" login forms.
  #
  def signin_get
    render_signin
  end

  # This action received the email signin form.
  def signin_post
    email, password = *params[:identity].values_at(:email, :password)
    @identity = Identity::Email.authenticate(email, password)
    unless @identity
      @identity = Identity::Email.new(:email => email)
      flash.now[:error] = I18n.t("signin.message.error")
      
      return render_signin
    end
    
    flash[:success] = I18n.t("signin.message.success")
      
    signin @identity.user
    redirect_to_target
  end
  
  private

  def render_signin
    @identity ||= Identity::Email.new
    render :action => "new", :locals => { :partials => signin_partials }
  end

  def signin_partials
    case params[:req]
    when "twitter" then %w(twitter_signin)
    when "email"
      # Show email signin form, when not logged in; show
      # email signup form, when the user is logged in but has no email identity.
      current_user ? %w(email_signup) : %w(email_signin)
    when "confirmed"
      # show email signin form, when not logged in; show email signup
      # form, when logged in, but no email identity is present; show
      # email confirmation form when email identity is not confirmed.
      current_user.nil? ? %w(email_signin) : 
      current_user.identity(:email).nil? ? %w(email_signup) :
      %w(email_confirmation)
    else
      %w(email_signin twitter_signin)
    end
  end
  
  public
  
  # This action renders the signup forms. 
  #
  def signup_get
    if current_user
      raise "user is already logged in"
    end
    
    @identity = Identity::Email.new
    render_signup
  end
  
  def signup_post
    @identity = Identity::Email.create(params[:identity])

    # If identity could not be saved.
    unless @identity.id
      render_signup
      return
    end
    
    flash[:success] = I18n.t("signin.message.success", :name => @identity.name)
    signin @identity.user
    redirect_to @identity.user
  end
  
  private
  
  def signup_partials
    case params[:req]
    when "twitter"            then %w(twitter_signin)
    when "email", "confirmed" then %w(email_signup)
    else                      %w(email_signup twitter_signin)
    end
  end

  def render_signup
    render :action => "new", :locals => { :partials => signup_partials }
  end

  public
  
  def signout_delete
    signout
    redirect_to root_path
  end
  
  # --- Twitter callbacks ---------------------------------------------
  
  # The "twitter_post" action initiates a twitter signup. It is a front
  # for the TwitterAuthMiddleware. TwitterAuthMiddleware redirects to
  # the "twitter" action after the Twitter oauth dance is over.
  def twitter_post
    # the create method receives the sessions/by_twitter form (which
    # basically creates just a "yes, I want to follow" checkbox.)

    # We store the form data in the session, to be evaluated in the
    # "twitter" action.
    identity = params[:identity] || {}
    session[:follow_bountyhill] = identity[:follow_bountyhill] if identity

    # The TwitterAuthMiddleware intercepts "/tw/" URLs. The "/tw/login" 
    # URL sets up and redirects to twitter auth. When Twitter oauth
    # returns to TwitterAuthMiddleware, which then redirects to the 
    # "twitter" action.
    redirect_to "/tw/login"
  end

  # The created action is where the TwitterAuthMiddleware will redirect 
  # to after the user logged in successfully.
  def twitter
    follow_bountyhill = session.delete(:follow_bountyhill)

    if current_user
      # At this point an existing user might have signed in for the first time,
      # or might just revisit the site. In the latter case we don't produce a flash message.
      if Time.now - current_user.created_at < 5
        flash[:success] = "twitter_sessions.success".t
      end

      # follow @bountyhill?
      if follow_bountyhill
        current_user.identity(:twitter).follow
        flash[:success] = "twitter_sessions.following".t
      end
    end

    redirect_to_target
  end

  # The failed action is where the TwitterAuthMiddleware will redirect to
  # after the user cancelled log in.
  def twitter_failed
    session.delete(:follow_bountyhill)
    redirect_to_target
  end

  private

  def redirect_to_target
    after_signin = session.delete(:after_signin)
    redirect_to(after_signin || current_user || root_path)
  end  
end
