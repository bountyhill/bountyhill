# encoding: UTF-8

class SessionsController < ApplicationController
  
  skip_before_filter  :show_confirmation_reminder
  before_filter       :set_partials,          :only => [:signin_get]
  before_filter       :set_identity_params,   :only => [:signin_post]
  
  #
  # This action renders signin forms. 
  # The "req" parameter determines which forms to show:
  #
  # - "email": show email signin form, when not logged in; show email
  #   signup form, when logged in, but no email identity is present.
  # - "twitter": show twitter signin form.
  # - "facebook": show facebook signin form.
  # - "google": show google signin form.
  # - "linkedin": show linkedin signin form.
  # - "xing": show xing signin form.
  # - "confirmed": show email signin form, when not logged in; show email
  #   signup form, when logged in, but no email identity is present.
  #   show "confirmed" when email identity is present but not confirmed.
  # - all other values: show all available login forms.
  #
  def signin_get
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
    @mode = if  params[:do_reset]   then :reset
      elsif     params[:do_signin]  then :signin
      else      :signup
      end
      
    email, password = @identity_params.values_at(:email, :password)
    @identity = case @mode
      when :signin  then Identity::Email.authenticate(email, password)
      when :signup  then Identity::Email.create(@identity_params)
      when :reset   then Identity::Email.where("lower(email)=?", email.downcase).first
      end || Identity::Email.new(@identity_params)
      
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
        when :signin  then "sessions/forms/signin"
        when :reset   then "sessions/forms/signin"
        when :signup  then "sessions/forms/email"
        end
    end
  end
  
  def cancel
    flash[:warn] =  if current_user then  I18n.t("sessions.auth.skip")
                    else                  I18n.t("sessions.auth.cancel")
                    end
    identity_cancelled!
  end
  
  def destroy
    signout
    flash[:notice] = I18n.t("sessions.auth.destroy")
    redirect_to root_path
  end
  
protected

  def set_partials
    @partials = case params[:req]
      when "confirmed"  then identity?(:email) ? %w(confirm) : %w(signin email)
      when "address"    then %w(address)
      when "twitter"    then %w(twitter)
      when "facebook"   then %w(facebook)
      when "google"     then %w(google)
      when "linkedin"   then %w(linkedin)
      when "xing"       then %w(xing)
      when "email"      then %w(signin email)
      else              %w(signin twitter facebook google linkedin xing email)
      end
  end

  def set_identity_params
    @identity_params = if (identity_key = params.keys.detect{ |key| key.to_s.include?("identity_") })
      params[identity_key]
    end
    @identity_params ||= {}
  end
    
end
