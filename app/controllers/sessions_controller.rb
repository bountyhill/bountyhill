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
    @identity = Identity::Email.new(:newsletter_subscription => true)
    @mode = :signin
    
    if params[:req].present? && !ApplicationController::RequiredIdentity.payload(session)
      @mode = :signup
      kind = params[:req].to_sym
      back = request.env["HTTP_REFERER"]
      
      ApplicationController::RequiredIdentity.set_payload(session, 
        :on_success => back, :on_cancel => back, :kind => kind)
    end
    
    render_signin!
  end

  # This action received the email signin/signup form.
  def signin_post
    attrs = params[:identity] || {}
    @mode = if params[:do_reset] then :reset
      elsif params[:do_signin] then :signin
      elsif params[:do_signup] then :signup
      else  raise "Unknown signin mode"
      end
      
    email, password = attrs.values_at(:email, :password)
    @identity = case @mode
      when :signin  then Identity::Email.authenticate(email, password)
      when :signup  then Identity::Email.create(attrs)
      when :reset   then Identity::Email.where("lower(email)=?", email.downcase).first
      end || Identity::Email.new(attrs)
      
    if @identity.id
      # Success! Set flash, and go somewhere...
      
      flash[:success] = I18n.t("identity.form.success.#{@mode}", :name => @identity.name)
      
      case @mode
      when :signup, :signin
        signin @identity.user
        identity_presented!
      when :reset
        Deferred.mail UserMailer.reset_password(@identity.user)
        redirect_to "/"
      end
    end
    
    # Error: @identity is not in the database. 
    # -> validation failed, invalid email/password, etc.
    @error = I18n.t("identity.form.error.#{@mode}")
    @partial = case @mode
      when :signin  then "sessions/forms/email"
      when :reset   then "sessions/forms/email"
      when :signup  then "sessions/forms/register"
      end
  end

  private

  def render_signin!
    @partials = case params[:req]
    when "confirmed"  then identity?(:email) ? %w(confirm) : %w(email register)
    when "twitter"    then %w(twitter)
    when "facebook"   then %w(facebook)
    when "email"      then %w(email register)
    else              %w(email twitter facebook register)
    end

    render! :action => "new", :layout => "dialog"
  end

  public
  
  def cancel
    identity_cancelled!
  end
  
  def signout_delete
    signout
    redirect_to root_path
  end

  # --- Facebook callbacks ---------------------------------------------
  
  # The "facebook_post" action initiates a facebook signup. It is a front
  # for the OmniAuthMiddleware. OmniAuthMiddleware redirects to
  # the "facebook" action after the Facebook oauth dance is over.
  def facebook_post
    # the create method receives the sessions/by_facebook form

    # We store the form data in the session, to be evaluated in the
    # "facebook" action.
    identity = params[:identity] || {}
    # TODO:
    # session[:like_bountyhill] = identity[:like_bountyhill]
    
    # The OmniAuthMiddleware intercepts "/auth/" URLs. The "/auth/facebook" 
    # URL sets up and redirects to facebook auth. When Facebook oauth
    # returns to OmniAuthMiddleware, which then redirects to the 
    # "facebook" action.
    redirect_to "/auth/facebook"
  end
  
  # The created action is where the OmniAuthMiddleware will redirect 
  # to after the user logged in successfully.
  def facebook
    if (uid = env["omniauth.auth"].uid)
      # After a successful facebook signin
      identity = ::Identity::Facebook.find_or_create(
        :uid              => uid,
        :oauth_token      => env["omniauth.auth"].credentials.token,
        :oauth_expires_at => Time.at(env["omniauth.auth"].credentials.expires_at),
        :info             => env["omniauth.auth"].info,
        :user             => current_user
      )
      signin(User.find(identity.user.id))

      # At this point an existing user might have signed in for the first time,
      # or might just revisit the site. In the latter case we don't produce a 
      # flash message.
      if Time.now - current_user.created_at < 5
        flash[:success] = "sessions.facebook.success".t
      end

      identity_presented!
    else
      flash[:error] = "sessions.facebook.error".t
      identity_cancelled!
    end
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
    session[:follow_bountyhermes] = identity[:follow_bountyhermes]

    # The TwitterAuthMiddleware intercepts "/tw/" URLs. The "/tw/login" 
    # URL sets up and redirects to twitter auth. When Twitter oauth
    # returns to TwitterAuthMiddleware, which then redirects to the 
    # "twitter" action.
    redirect_to "/tw/login"
  end

  # The created action is where the TwitterAuthMiddleware will redirect 
  # to after the user logged in successfully.
  def twitter
    follow_bountyhermes = session.delete(:follow_bountyhermes)
    
    screen_name, oauth_token, oauth_secret, info = *TwitterAuthMiddleware.session_info(session)

    if screen_name
      # After a successful twitter signin
      identity = ::Identity::Twitter.find_or_create(
        :info => info,
        :user => current_user,
        :screen_name  => screen_name,
        :oauth_token  => oauth_token,
        :oauth_secret => oauth_secret
      )
      signin(User.find(identity.user.id))

      # At this point an existing user might have signed in for the first time,
      # or might just revisit the site. In the latter case we don't produce a 
      # flash message.
      if Time.now - current_user.created_at < 5
        flash[:success] = "sessions.twitter.success".t
      end

      # follow @bountyhermes?
      if follow_bountyhermes
        twitter = current_user.identity(:twitter)
        if twitter.follow
          twitter.direct_message "notice.tweet.thanks_for_following".t
        end
      end

      identity_presented!
    else
      flash[:error] = "sessions.twitter.error".t
      identity_cancelled!
    end
  end

  private

  def redirect_to_target
    after_signin = session.delete(:after_signin)
    redirect_to(after_signin || current_user || root_path)
  end  
end
