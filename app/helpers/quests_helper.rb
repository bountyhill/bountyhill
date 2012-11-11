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
  
  def render_bounty_badge(object)
    expect! object => [Quest, Offer]
    
    div object.bounty.to_s(:cents => false), :class => "bounty_badge #{bounty_class(object)}"
  end
  
  def bounty_class(object)
    expect! object => [Quest, Offer]
    
    amount = object.bounty.to_f
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
