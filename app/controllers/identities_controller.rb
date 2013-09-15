# encoding: UTF-8

class IdentitiesController < ApplicationController
  before_filter :set_identity,        :except => [:new, :create, :failure]
  before_filter :set_identity_params, :only   => [:new, :update]
  
  # --- Omniauth social identities actions ---------------------------------------------
  # The following actions initiate omniauth signups. It is an initiator
  # and callback of the OmniAuthMiddleware. 

  #
  # the new action redirects to the given authentication provider
  # to perform the oauth dance.
  def new
    provider = params[:provider]
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
       (provider = request.env["omniauth.auth"].provider).present?
       
      @identity = Identity.provider(provider.to_sym).find_or_create(uid, current_user, request.env["omniauth.auth"])
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
    
  def update 
    raise RuntimeError, "Only allowed on email identity, but was called on: #{@identity.inspect}" unless @identity.kind_of?(Identity::Email)
    
    if Identity::Email.authenticate(@identity.email, @identity_params[:password])
      if @identity.update_attributes(
          :password               => @identity_params[:password_new],
          :password_confirmation  => @identity_params[:password_new_confirmation])

        flash[:success] = I18n.t("message.update.success", :record => Identity::Email.human_attribute_name(:password))
        redirect_to! @user
      else
        @identity.errors.add :password_new, @identity.errors.delete(:password).last
      end
    else
      @identity.errors.add :password, I18n.t("message.password.invalid")
    end
    @partial = "identities/email"
  end

  def destroy
    raise RuntimeError, "Identity #{params[:provider]} is the only identity of user #{@user.inspect}" if @user.identities == [@identity]
    
    @identity.destroy
    
    flash[:success] = I18n.t("message.destroy.success", :record => "identity/#{params[:provider]}".camelize.constantize.model_name.human)
    redirect_to! @user
  end
  
protected

  def set_identity
    @identity = Identity.find(params[:id])
    @user     = @identity.user
    raise(ArgumentErrorr, "Not allowed") unless current_user && @user == current_user
  end

  def set_identity_params
    @identity_params = if (identity_key = params.keys.detect{ |key| key.to_s.include?("identity_") })
      params[identity_key]
    else
      {}
    end
  end
  
  def pre_process_twitter_signin
    # We store the form data in the session, to be handled after twitter oauth signin
    session[:follow_bountyhermes] = @identity_params[:follow_bountyhermes]
  end
  
  def post_process_twitter_signin
    # handle the data provided by the user before twitter oauth signin
    if session.delete(:follow_bountyhermes)
      @identity.follow
      @identity.direct_message I18n.t("tweet.follow.success")
    end
  end

end
