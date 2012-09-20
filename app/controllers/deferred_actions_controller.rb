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

  protected
  
  # reset a password.
  def perform_reset_password
    sign_in(action.actor)
  end

  # reset a password.
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
