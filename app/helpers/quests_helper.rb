module QuestsHelper
  def render_bounty_ribbon(quest)
    expect! quest => [Quest, Offer]
    
    if quest.is_a?(Offer)
      quest = quest.quest
    end
    
    amount = quest.bounty.to_f
    return unless amount > 0
    
    if amount < 100
      bounty_class = "small"
      amount = amount.round
    elsif amount < 1000
      bounty_class = "medium"
      amount = 10 * (amount / 10).round
    else 
      bounty_class = "large"
      amount = 100 * (amount / 100).round
    end

    currency = quest.bounty.currency.to_s
    if currency == "EUR"
      currency = "&euro;"
    end
    
    div :class => "ribbon-wrapper right" do
      div :class => "ribbon #{bounty_class}" do
        "#{currency} #{amount}".html_safe
      end
    end
  end
end
