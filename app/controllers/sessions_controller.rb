# encoding: UTF-8

class SessionsController < ApplicationController
  
  skip_before_filter  :show_confirmation_reminder
  before_filter       :set_partials, :only => [:signin_get]
  
  #
  # This action renders signin forms. 
  # The "req" parameter determines which forms to show:
  #
  # - "email": show email signin form, when not logged in; show email
  #   signup form, when logged in, but no email identity is present.
  # - "twitter": show twitter signin form.
  # - "facebook": show facebook signin form.
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
        :on_success => back,
        :on_cancel  => back,
        :kind       => kind)
    end
    
    render! :action => "new", :layout => "dialog"
  end

  # This action received the email signin/signup form.
  def signin_post
    attrs = params[:identity] || {}
    @mode = if  params[:do_reset]   then :reset
      elsif     params[:do_signin]  then :signin
      elsif     params[:do_signup]  then :signup
      else      raise ArgumentError, "Unknown signin mode"
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
        redirect_to root_path
      end
    else
      # Error: @identity is not in the database. 
      # -> validation failed, invalid email/password, etc.
      @error = I18n.t("identity.form.error.#{@mode}")
      @partial = case @mode
        when :signin  then "sessions/forms/email"
        when :reset   then "sessions/forms/email"
        when :signup  then "sessions/forms/register"
        end
    end
  end
  
  def cancel
    flash[:notice] = I18n.t("sessions.auth.cancel")
    identity_cancelled!
  end
  
  def destroy
    signout
    flash[:notice] = I18n.t("sessions.auth.destroy")
    redirect_to root_path
  end
  
  # --- Omniauth entries ---------------------------------------------
  # The following actions initiate omniauth signups. It is an initiator
  # and callback of the OmniAuthMiddleware. 

  #
  # the new action redirects to the given authentication provider
  # to perform the oauth dance.
  def new
    @identity_params  = params[:identity] || {}
    provider          = params[:provider]

    pre_process_method = "pre_process_#{provider}_signin"
    self.send(pre_process_method) if self.respond_to?(pre_process_method)
    
    # The OmniAuthMiddleware intercepts "/auth/" URLs, e.g. the "/auth/facebook" 
    # URL sets up and redirects to facebook auth. When Facebook oauth
    # returns to OmniAuthMiddleware, which then redirects to the "create" action.
    redirect_to "/auth/#{provider}"
  end
  
  #
  # OmniAuthMiddleware receives the providers (successful) oauth infos and 
  # redirects to the create action after the oauth dance is over.
  def create
    if (uid = request.env["omniauth.auth"].uid).present? &&
       (provider  = request.env["omniauth.auth"].provider).present?
       
      @identity = Identity.of_provider(provider).find_or_create(uid, current_user, request.env["omniauth.auth"])
      signin(User.find(@identity.user.id))
      
      # At this point an existing user might have signed in for the first time,
      # or might just revisit the site. In the latter case we don't produce a flash message.
      flash[:success] = I18n.t("sessions.auth.success") if Time.now - current_user.created_at < 5
      
      # trigger post processing of actual provider
      post_process_method = "post_process_#{provider}_signin"
      self.send(post_process_method) if self.respond_to?(post_process_method)
      
      identity_presented!
    else
      flash[:error] = I18n.t("sessions.auth.error")
      identity_cancelled!
    end
  end

  # OmniAuthMiddleware receives the providers (unsuccessful) oauth and 
  # redirects to the failure action after the oauth dance is over.
  def failure
    flash[:error] = I18n.t("sessions.auth.failure")
    identity_cancelled!
  end


private

  def set_partials
    @partials = case params[:req]
      when "confirmed"  then identity?(:email) ? %w(confirm) : %w(email register)
      when "twitter"    then %w(twitter)
      when "facebook"   then %w(facebook)
      when "email"      then %w(email register)
      else              %w(email twitter facebook register)
      end
  end

  def pre_process_twitter_signin
    # We store the form data in the session, to be handled after twitter oauth signin
    session[:follow_bountyhermes] = @identity_params[:follow_bountyhermes]
  end
  
  def post_process_twitter_signin
    # handle the data provided by the user before twitter oauth signin
    if (twitter_identity.follow = session.delete(:follow_bountyhermes))
      @identity.direct_message I18n.t("notice.tweet.thanks_for_following")
    end
  end
    
end
