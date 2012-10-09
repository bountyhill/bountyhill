# encoding: utf-8

# The Account model.
#
# The Account model is the monetary account for a user. All financial transactions
# are recorded here.
class Account < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"
  has_many :liabilities
  
  def balance
    cents = Liability.where(:account_id => self).sum(:amount_in_cents)
    Money.new(cents || 0, Money.default_currency)
  end

  # Balance an offer
  def self.balance(offer)
    expect! offer => Offer
    expect! offer.accepted?
    
    quest = offer.quest
    
    # -- split bounty amount ------------------------------------------
    
    offer_amount = quest.bounty * 0.5
    bh_amount = quest.bounty * 0.1
    recommendation_amount = quest.bounty - offer_amount - bh_amount

    last5 = offer.chain.last(5)
    if last5.present?
      recommender_amount = recommendation_amount / last5.length 
    end

    # -- store liabilities --------------------------------------------
    
    transaction do
      Liability.generate quest.bounty, quest.owner => User.admin, :reference => offer
      Liability.generate offer_amount, User.admin => offer.owner, :reference => offer

      last5.each do |user|
        Liability.generate recommender_amount, User.admin => user, :reference => offer
      end
    end
  end
end
