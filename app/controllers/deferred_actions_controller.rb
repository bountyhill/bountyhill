class DeferredActionsController < ApplicationController
  attr_reader :action
  
  # Execute a deferred action. An URL should look like this:
  #    /act?thisismysecret
  # but could also be 
  #    /act?id=thisismysecret
  def show
    secret = params.key(nil) || params[:id]

    @action = DeferredAction.find_by_secret(secret)
    
    unless action && action.performable?
      flash[:error] = I18n.t "deferred_actions.invalid"
      redirect_to "/"
      return
    end
    
    # Perform the action. Next to running a perform_XXX action, 
    # this also does some bookkeeping.
    action.perform! :on => self
    
    show_success_message
    
    # When not rendered nor redirected, redirect to start page.
    redirect_to "/" unless performed?
  end

  
  before_filter :verify_method

  def verify_method
    expected_method = case action_name
    when "show" then "GET"
    else             "POST"
    end

    return if expected_method == request.method
    
    flash[:error] = "Don't know how to handle this request. Should be a #{expected_method}"
    redirect_to "/"
  end
  
  # Send an email address confirmation email.
  #
  def confirm
    Deferred.mail UserMailer.confirm_email(current_user)
    flash[:success] = I18n.t("signup.confirm.sent")
    
    redirect_to "/"
  end

  # Send a reset password email.
  def reset_password
    if email = params[:email]
      identity = Identity::Email.where("lower(email)=?", email.downcase).first
    end
    
    if identity
      Deferred.mail UserMailer.reset_password(identity.user)
      flash[:success] = I18n.t("reset_password.sent")
    else
      flash[:error] = I18n.t("reset_password.unknown_email", :email => email)
    end
    redirect_to "/"
  end

  protected
  
  # reset a password.
  def perform_reset_password
    signin(action.actor)
  end

  # confirm email address.
  def perform_confirm_email
    action.actor.confirm_email!
  end
  
  private
  
  # If the flash is not set (neither flash[:success] nor flash[:error], and
  # a translation for "actions.<name>" exists, then we set
  # a success message.
  def show_success_message
    return unless flash[:success].blank? && flash[:error].blank?

    flash[:success] = I18n.translate!("deferred_actions.#{action.action}")
  rescue I18n::MissingTranslationData
  end
end
