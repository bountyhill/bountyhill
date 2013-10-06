# encoding: UTF-8

class UserMailer < ActionMailer::Base
  layout "../user_mailer/layout"
  
  default :from => 'info@bountyhill.com'
  default :css  => 'email' # roadie option convert styles in this css file into inline styles

  # This is a temporary default_url_option. It will be adjusted by
  # ApplicationController once the first request comes in.
  default_url_options[:host] = "bountyhill.local"
  default_url_options[:port] = 3000 if Rails.env.development?
  
  # Confirm email address, please.
  def confirm_email(user)
    action = DeferredAction.create!(:actor => user, :action => "confirm_email")
    @url = action.url

    mail(:to => email(user),
      :subject => subject(I18n.t("mail.confirm_email.subject")))
  end
  
  # Forgot passwor?
  def reset_password(user)
    action = DeferredAction.create!(:actor => user, :action => "reset_password")
    @url = action.url

    mail(:to => email(user),
      :subject => subject(I18n.t("mail.reset_password.subject", :email => user.email)))
  end
  
  # -- Offer emails ---------------------------------------------------
  
  # "[Bountyhill] You received an offer on your quest '%{title}'"
  def offer_received(offer)
    @quest, @offer = offer.quest, offer

    mail(:to => email(@quest.owner),
      :subject => subject(I18n.t("mail.offer_received.subject")))
  end
  
  # "[Bountyhill] An offer has been withdrawn"
  def offer_withdrawn(offer)
    @quest, @offer = offer.quest, offer
    
    mail(:to => email(@quest.owner),
      :subject => subject(I18n.t("mail.offer_withdrawn.subject")))
  end
  
  # "[Bountyhill] Your offer '%{title}' has been accepted"
  def offer_accepted(offer)
    @quest, @offer = offer.quest, offer
    
    mail(:to => email(@offer.owner),
      :subject => subject(I18n.t("mail.offer_accepted.subject")))
  end
  
  # "[Bountyhill] Your offer '%{title}' has been rejected"
  def offer_rejected(offer)
    @quest, @offer = offer.quest, offer
    
    mail(:to => email(@offer.owner),
      :subject => subject(I18n.t("mail.offer_rejected.subject")))
  end
  
protected

  def subject(text)
    "[bountyhill] #{text}"
  end

  def email(user)
    "#{user.name} <#{user.email}>"
  end

end
