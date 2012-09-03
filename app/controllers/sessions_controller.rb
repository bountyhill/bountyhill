class SessionsController < ApplicationController
  def new
  end

  def create
    if (user = Identity::Email.find_by_email(params[:session][:email])) && user.authenticate(params[:session][:password])
      flash[:success] = I18n.t("signin.message.success")
      sign_in user
      redirect_to user
    else
      flash.now[:error] = I18n.t("signin.message.error")
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end
end
