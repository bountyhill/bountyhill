class IdentitiesController < ApplicationController
  def new
    @identity = Identity::Email.new
  end

  def show
    @identity = Identity::Email.find(params[:id])
  end

  def create
    @identity = Identity::Email.new(params[:identity])
    if @identity.save
      sign_in @identity
      flash[:success] = I18n.t("signin.message.success", :default => "Welcome on bountyhill!", :name => @identity.name)
      redirect_to @identity
    else
      render :new
    end
  end

end
