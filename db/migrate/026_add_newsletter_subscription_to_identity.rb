class AddNewsletterSubscriptionToIdentity < ActiveRecord::Migration
  def change
    add_column  :identities, :newsletter_subscription, :boolean
  end
end