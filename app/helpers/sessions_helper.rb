# encoding: UTF-8

module SessionsHelper

  def link_to_cancel_signin
    # The "btn-cancel" class is here to control the appeareance of the cancel button. 
    link_to I18n.t("button.cancel"), "/sessions/cancel", :class => "btn btn-cancel", :method => :post
  end
  
end