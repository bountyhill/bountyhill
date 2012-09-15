module QuestsHelper
  def render_bounty_ribbon(quest)
    amount = quest.bounty.to_f
    
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
    
    div :class => "ribbon-wrapper left" do
      div :class => "ribbon #{bounty_class}" do
        "#{currency} #{amount}".html_safe
      end
    end
  end

  def quest_image_link_to(quest, options)
    zoom = options.delete(:zoom) && "zoom"
    link_to image_for(quest, options), quest, 
      :class => zoom, "data-bitly-type" => "bitly_hover_card"
  end
end
