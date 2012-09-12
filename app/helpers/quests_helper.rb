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
    
    content_tag :div, :class => "ribbon-wrapper left" do
      content_tag :div, :class => "ribbon #{bounty_class}" do
        "#{currency} #{amount}".html_safe
      end
    end
  end

  def quest_image_link_to(quest, options)
    link_to quest_image(quest, options), quest, 
      :class => "zoom", "data-bitly-type"=>"bitly_hover_card"
  end

  def quest_image(quest, options)
    img = image_for quest, :class => "zoom", :width => 330, :height => 205
    "#{img}\n#{zoomOverlay}#{image_highlight}".html_safe
  end
  
  def zoomOverlay
    '<span class="zoomOverlay"></span>'
  end

  def image_highlight
    '<div class="image_highlight"></div>'
  end
end
