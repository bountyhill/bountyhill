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
    @identity = Identity::Email.new(:email => params[:email])
    @mode = :signin

    render_signin!
  end

  # This action received the email signin/signup form.
  def signin_post
    @mode = params[:do_signup] ? :signup : :signin
    attrs = params[@mode] || {}
    
    if @mode == :signin
      email, password = attrs.values_at(:email, :password)

      @identity = Identity::Email.authenticate(email, password) || Identity::Email.new(attrs)
    else
      @identity = Identity::Email.create(attrs)
    end
    
    # Success: @identity is in the database, else error (validation failed or
    # invalid message/password)
    unless @identity.id
      @error = I18n.t("sessions.email.error.#{@mode}")
      # flash.now[:error] = @error
      render_signin!
    end
    
    flash[:success] = I18n.t("sessions.email.success.#{@mode}", :name => @identity.name)
    
    signin @identity.user
    identity_presented!
  end

  private

  def render_signin!
    partials = case params[:req]
    when "confirmed"  then identity?(:email) ? %w(email_confirmation) : %w(email)
    when "twitter"    then %w(twitter)
    when "email"      then %w(email)
    else              %w(email twitter)
    end

    render! :action => "new", :locals => { :partials => partials }
  end

  public
  
  def cancel
    identity_cancelled!
  end
  
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
    
    screen_name, oauth_token, oauth_secret, info = *TwitterAuthMiddleware.session_info(session)

    if screen_name
      # After a successful twitter signin
      identity = ::Identity::Twitter.find_or_create :info => info, 
                    :user => current_user,
                    :screen_name  => screen_name,
                    :oauth_token  => oauth_token,
                    :oauth_secret => oauth_secret

      signin(User.find(identity.user.id))

      # At this point an existing user might have signed in for the first time,
      # or might just revisit the site. In the latter case we don't produce a 
      # flash message.
      if Time.now - current_user.created_at < 5
        flash[:success] = "sessions.twitter.success".t
      end

      # follow @bountyhill?
      if follow_bountyhill
        current_user.identity(:twitter).follow
        flash[:success] = "sessions.twitter.following".t
      end

      identity_presented!
    else
      session.delete(:follow_bountyhill)
      identity_cancelled!
    end
  end

  private

  def redirect_to_target
    after_signin = session.delete(:after_signin)
    redirect_to(after_signin || current_user || root_path)
  end  
end
