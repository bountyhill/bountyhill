class UserMailer < ActionMailer::Base
  default from: "info@bountyhill.com"

  # This is a temporary default_url_option. It will be adjusted by
  # ApplicationController once the first request comes in.
  default_url_options[:host] = "bountyhill.local"
  
  # Confirm email address, please.
  def confirm_email(user)
    action = DeferredAction.create!(:actor => user, :action => "confirm_email")
    @url = action.url

    mail(:to => user.email, :subject => I18n.t("mail.confirm_email", :email => user.email))
  end
  
  # Forgot passwor?
  def reset_password(user)
    action = DeferredAction.create!(:actor => user, :action => "reset_password")
    @url = action.url

    mail(:to => user.email, :subject => I18n.t("mail.reset_password", :email => user.email))
  end
end
