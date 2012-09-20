class SessionsController < ApplicationController
  def new
    @identity = Identity::Email.new
  end

  def create
    email, password = *params[:identity].values_at(:email, :password)
    if @identity = Identity::Email.authenticate(email, password)
      flash[:success] = I18n.t("signin.message.success")
      
      sign_in @identity.user
      redirect_to @identity.user
    else
      @identity = Identity::Email.new(:email => email)
      flash.now[:error] = I18n.t("signin.message.error")
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end
end
