class UsersController < ApplicationController
  
  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      flash[:success] = I18n.t("signin.message.success", :default => "Welcome on bountyhill!", :name => @user.name)
      redirect_to @user
    else
      render :new
    end
  end

end
