# encoding: UTF-8

module SessionsHelper

  def link_to_cancel_signin
    # The "btn-cancel" class is here to control the appeareance of the cancel button. 
    link_to I18n.t("button.cancel"), "/sessions/cancel", :class => "btn btn-cancel", :method => :post
  end
  
  def signin_button_toggle_javascript(identity)
    expect! identity => Symbol

    js = javascript_tag <<-JS
      if ($("#agree_to_terms_#{identity}")[0]){
        $("#signin_#{identity}").attr("disabled", "disabled");
        
        $("#agree_to_terms_#{identity}").change(function() {
          if($(this).is(':checked'))
            $("#signin_#{identity}").removeAttr("disabled");
          else
            $("#signin_#{identity}").attr("disabled", "disabled");
        });
      }
    JS
    
    js.html_safe
  end
  
end