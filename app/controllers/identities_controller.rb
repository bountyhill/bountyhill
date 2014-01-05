# encoding: UTF-8

class IdentitiesController < ApplicationController
  before_filter :set_identity, :except => [:new, :create, :init, :success, :failure]
  before_filter :set_identity_params
  before_filter :set_provider
  
  def new
    # render the new modal dialoge of the requested identity
    @identity = Identity.provider(@provider).new
    render :layout => 'dialog'
  end
  
  def create
    @identity = Identity.provider(@provider).new(@identity_params)
    @identity.user = current_user || Identity.find_user(@identity_params)
    
    return unless @identity.save

    # if the identity was requested to perform another action
    # we have to call identity_presented! to trigger it's on susscess callback 
    return identity_presented! if identity_requested?(@provider)
    
    flash[:success] = I18n.t("notice.add.success", :record => @identity.class.model_name.human)
    redirect_to!(user_path(@identity.user))
  end

  def edit
    render :layout => 'dialog'
  end
  
  def update 
    # identity email updates have to be handled differently since
    # it has to be confirmed with user's current password
    return update_email if @identity.kind_of?(Identity::Email)

    @identity.attributes = @identity_params
    if @identity.save
      flash[:success] = I18n.t("notice.update.success", :record => @identity.class.model_name.human)
      redirect_to! @user
    end
  end

  def delete
    render :layout => 'dialog'
  end
  
  def destroy
    raise RuntimeError, "Identity #{@provider} is the only identity of user #{@user.inspect}"  if @identity.solitary?
    @identity.destroy
    
    flash[:success] = I18n.t("notice.remove.success", :record => "identity/#{@provider}".camelize.constantize.model_name.human)
    redirect_to! user_path(@user)
  end
  
  
  # --- Omniauth social identities actions ---------------------------------------------
  # The following actions initiate omniauth signups. It is an initiator
  # and callback of the OmniAuthMiddleware. 
  
  #
  # redirect to the given authentication provider
  # to perform the oauth dance for identities handled by OmniAuth
  def init
    # The OmniAuthMiddleware intercepts "/auth/" URLs, e.g. the "/auth/facebook" 
    # URL sets up and redirects to facebook auth. When Facebook oauth
    # returns to OmniAuthMiddleware, which then redirects to the "create" action.
    pre_process_signin # trigger pre processing
    redirect_to "/auth/#{@provider}"
  end
  
  #
  # OmniAuthMiddleware receives the providers (successful) oauth infos and
  # redirects to the create action after the oauth dance is over.
  def success
    if (uid = request.env["omniauth.auth"].uid).present? && @provider.present?

      # At this point an existing user might have signed in for the first time,
      # or might just revisit the site. In the latter case we don't produce a flash message.
      flash[:success] = if current_user then  I18n.t("notice.add.success", :record => Identity.provider(@provider).new.class.model_name.human)
                        else                  I18n.t("sessions.auth.success")
                        end
      
      @identity = Identity.provider(@provider).find_or_create(uid, current_user, request.env["omniauth.auth"])
      signin(User.find(@identity.user.id))
      post_process_signin # trigger post processing
      
      identity_presented!
    else
      flash[:error] = if current_user then  I18n.t("notice.add.error", :record => Identity.provider(@provider).new.class.model_name.human)
                      else                  I18n.t("sessions.auth.failure")
                      end
      identity_cancelled!
    end
  end
  
  # OmniAuthMiddleware receives the providers (unsuccessful) oauth and 
  # redirects to the failure action after the oauth dance is over.
  def failure
    flash[:error] = I18n.t("sessions.auth.failure")
    identity_cancelled!
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
  
  def set_provider
    # provider is explicitly set in params
    @provider = params[:provider]
    
    # provider is given by identity
    @provider ||= @identity.provider if @identity

    # provider is given by identity key in params hash
    @provider ||= if (identity_key = params.keys.detect{ |key| key.to_s.include?("identity_") })
        identity_key.split("identity_").last
      end
      
    # provider is set in request by omniauth
    @provider ||= request.env["omniauth.auth"] && request.env["omniauth.auth"].provider
    
    # return symbolized provider if present
    @provider = @provider.to_sym if @provider.present?
  end
  
  def pre_process_signin
    # store the form data in the session, to be handled after oauth signin
    session[:identity_params] = @identity_params
    
    # trigger provider specific pre-processing
    self.send("pre_process_#{@provider}_signin") if self.respond_to?("pre_process_#{@provider}_signin")
  end
  
  def post_process_signin
    # fetch the form data provided by the user before oauth signin
    @identity_params = @identity_params.merge(session.delete(:identity_params) || {}).with_indifferent_access
    
    # set identity's commercial flag
    @identity.update_attributes(:commercial => true) if @identity_params[:commercial]
    
    # trigger provider specific post-processing
    self.send("post_process_#{@provider}_signin") if self.respond_to?("post_process_#{@provider}_signin")
  end
  
  def post_process_twitter_signin
    return unless @identity_params[:follow_bountyhermes].present?
    
    # handle user wants to folllow bountyhermes
    @identity.follow
    @identity.direct_message I18n.t("tweet.follow.success")
  end
  
  def update_email
    if Identity::Email.authenticate(@identity.email, @identity_params[:password])
      if @identity.update_attributes(
          :password               => @identity_params[:password_new],
          :password_confirmation  => @identity_params[:password_new_confirmation])
        flash[:success] = I18n.t("notice.update.success", :record => Identity::Email.human_attribute_name(:password))
        redirect_to! user_path(@user)
      else
        @identity.errors.add :password_new, @identity.errors.delete(:password).last
      end
    else
      @identity.errors.add :password, I18n.t("notice.password.invalid")
    end
  end
end
