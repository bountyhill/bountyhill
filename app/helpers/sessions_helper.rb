module SessionsHelper
  def link_to_cancel_signin
    # The "btn-cancel" class is here to control the appeareance of the cancel button. 
    link_to I18n.t("cancel"), "/sessions/cancel", :class => "btn btn-cancel btn-small", :method => :post
  end

  def link_to_reset_password
    link_to I18n.t(:"reset_password.label"), 
      reset_password_path(:email => @identity.email), 
      :method => "post"
  end 
end