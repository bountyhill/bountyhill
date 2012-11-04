module QuestsHelper
  
  def share_button(quest)
    return unless quest.active?
    header_button(:twitter, share_path(quest), :title => t("quest.actions.tweet.title"), :rel => "nofollow")
  end

  def offer_button(quest)
    return unless !personal_page? && quest.active?
    header_button(:rect, new_offer_path(:quest_id => quest), :title => t("quest.actions.offer.title"), :rel => "nofollow")
  end

  def stop_quest_button(quest)
    return unless personal_page? && quest.active?
    header_button(:stop, run_path(quest), :title => t("quest.actions.stop.title"), :rel => "nofollow", :method => :delete)
  end

  def start_quest_button(quest)
    return unless personal_page? && !quest.active?
    header_button(:start, run_path(quest), :title => t("quest.actions.start.title"),  :rel => "nofollow")
  end
  
  def render_bounty_badge(quest)
    expect! quest => [Quest, Offer]
    
    div quest.bounty.to_s(:cents => false), :class => "bounty_badge #{bounty_class(quest)}"
  end
  
  def render_bounty_ribbon(quest)
    expect! quest => [Quest, Offer]
    
    div :class => "ribbon-wrapper right" do
      div quest.bounty.to_s(:cents => false), :class => "ribbon #{bounty_class(quest)}"
    end
  end
  
  def bounty_class(quest)
    expect! quest => [Quest, Offer]
    
    amount = quest.bounty.to_f
    return if amount <= 0
    
    if    amount < 100  then  "small"
    elsif amount < 1000 then  "medium"
    else                      "large"
    end
  end
  
  def quests_subtitle(count)
    scope = if personal_page? then "own"
            else params[:filter] || "all"
            end
    I18n.t "quests.filter.#{scope}.sub", :count => count
  end
  
  def render_sticker_note(options={})
    li :class => options[:html_class] do
      p("#{strong(options[:count])} #{options[:title]}") +
      small(options[:subtitle])
    end    
  end
end
