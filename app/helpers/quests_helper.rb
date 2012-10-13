module QuestsHelper
  def render_bounty_ribbon(quest)
    expect! quest => [Quest, Offer]

    amount = quest.bounty.to_f
    return if amount <= 0
    
    css = if amount < 100 then "small"
      elsif amount < 1000 then "medium"
      else "large"
      end
      
    div :class => "ribbon-wrapper right" do
      div quest.bounty.to_s(:cents => false), :class => "ribbon #{css}"
    end
  end
end
