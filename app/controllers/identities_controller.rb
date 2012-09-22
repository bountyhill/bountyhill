class IdentitiesController < ApplicationController
  include RequestedForms
  
  #
  # /signup - create an identity by email.
  def new
    @identity = Identity::Email.new
  end

  def create
    identity = Identity::Email.create(params[:identity])

    # If identity was valid and could be saved.
    if identity.id
      flash[:success] = I18n.t("signin.message.success", :name => identity.name)
      sign_in identity.user
      redirect_to identity.user
    else
      @identity = identity
      render :new
    end
  end
end
