module QuestsHelper
  def render_bounty_badge(quest)
    expect! quest => [Quest, Offer]

    amount = quest.bounty.to_f
    return if amount <= 0
    
    css = if amount < 100 then "small"
      elsif amount < 1000 then "medium"
      else "large"
      end
      
    div quest.bounty.to_s(:cents => false), :class => "bounty_badge #{css}"
  end
  
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
  
  def quests_subtitle(count)
    scope = if personal_page? then "own"
            else params[:filter] || "all"
            end
    I18n.t "quests.filter.#{scope}.sub", :count => count
  end
end
