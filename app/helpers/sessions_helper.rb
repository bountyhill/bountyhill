# encoding: UTF-8

module SessionsHelper

  def link_to_cancel_signin
    # The "btn-cancel" class is here to control the appeareance of the cancel button. 
    link_to I18n.t("button.cancel"), "/sessions/cancel", :class => "btn btn-cancel", :method => :post
  end
  
  def terms_of_use_legend
    I18n.t("identity.form.agree_to_terms", :link => link_to(I18n.t('identity.form.terms_link'), '/terms', :target => '_blank')).html_safe
  end
  
end