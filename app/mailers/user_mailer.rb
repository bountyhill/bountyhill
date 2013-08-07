# encoding: UTF-8

class UserMailer < ActionMailer::Base
  layout "../user_mailer/layout"
  
  default from: "info@bountyhill.com"

  # This is a temporary default_url_option. It will be adjusted by
  # ApplicationController once the first request comes in.
  default_url_options[:host] = "bountyhill.local"
  
  def subject(text)
    "[bountyhill] #{text}"
  end
  
  # Confirm email address, please.
  def confirm_email(user)
    action = DeferredAction.create!(:actor => user, :action => "confirm_email")
    @url = action.url

    mail(:to => user.email,
      :subject => subject(I18n.t("notice.mail.confirm_email", :email => user.email)))
  end
  
  # Forgot passwor?
  def reset_password(user)
    action = DeferredAction.create!(:actor => user, :action => "reset_password")
    @url = action.url

    mail(:to => user.email,
      :subject => subject(I18n.t("notice.mail.reset_password", :email => user.email)))
  end
  
  # -- Offer emails ---------------------------------------------------
  
  # "[Bountyhill] You received an offer on your quest %{title}"
  def offer_received(offer)
    @quest, @offer = offer.quest, offer

    mail(:to => @quest.owner.email, :cc => @offer.owner.email,
      :subject => subject(I18n.t("notice.mail.offer_received", :title => @quest.title)))
  end
  
  # "[Bountyhill] Your offer has been accepted %{title}"
  def offer_accepted(offer)
    @quest, @offer = offer.quest, offer
    
    mail(:to => @offer.owner.email, :cc => @quest.owner.email,
      :subject => subject(I18n.t("notice.mail.offer_accepted", :title => @quest.title)))
  end
  
  # "[Bountyhill] Your offer has been rejected %{title}"
  def offer_rejected(offer)
    @quest, @offer = offer.quest, offer
    
    mail(:to => @offer.owner.email, 
      :subject => subject(I18n.t("notice.mail.offer_rejected", :title => @quest.title)))
  end
  
  # "[Bountyhill] An offer has been withdrawn"
  def offer_withdrawn(offer)
    @quest, @offer = offer.quest, offer
    
    mail(:to => @quest.owner.email,
      :subject => subject(I18n.t("notice.mail.offer_withdrawn", :title => @quest.title)))
  end
end
