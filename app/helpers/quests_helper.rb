module QuestsHelper

  def quest_box(quest)
    expect! quest => Quest
    
    box(:quest, quest, :title => I18n.t("quest.box.title", :amount => quest.send(:bounty).to_s))
  end

  def quests_list_box(quests)
    expect! quests        => ActiveRecord::Relation
    expect! quests.first  => [Quest, nil]
    
    list_box(:quests, quests)
  end
  
  def quests_list_box_buttons
    button_group [
      new_quest_button
    ]
  end
  
  def new_quest_button
    modal_awesome_button(:edit, new_quest_path) { I18n.t("nav.start_quest") }
  end

  def categories_select_options
    I18n.t(:categories, :scope => :quest).map { |key, value| [ value, key ] }
  end
  
  def quest_buttons(quest)
    button_group [
      share_quest_button(quest),
      offer_quest_button(quest),
      stop_quest_button(quest),
      start_quest_button(quest),
      edit_quest_button(quest)
    ]
  end
  
  def share_quest_button(quest)
    return unless quest.active?
    modal_awesome_button(:retweet, share_path(quest), :rel => "nofollow") { I18n.t("button.share") }
  end

  def offer_quest_button(quest)
    return unless quest.active? && !current_user.owns?(quest)
    modal_awesome_button(:share, new_offer_path(:quest_id => quest), :rel => "nofollow") { I18n.t("button.offer") }
  end

  def start_quest_button(quest)
    return unless !quest.active? && current_user.owns?(quest)
    modal_awesome_button(:ok_circle, run_path(quest), :rel => "nofollow") { I18n.t("button.start") }
  end

  def stop_quest_button(quest)
    return unless quest.active? && current_user.owns?(quest)
    modal_awesome_button(:remove_sign, url_for(:controller => :runs, :action => :cancel, :id => quest), :rel => "nofollow") { I18n.t("button.stop") }
  end
  
  def edit_quest_button(quest)
    return unless !quest.active? && current_user.owns?(quest)
    modal_awesome_button(:edit, edit_quest_path(quest), :rel => "nofollow") { I18n.t("button.edit") }
  end
  
  def quest_statistic(quest)
    dl :class => "statistic" do
      quest_statistic_entries(quest).join.html_safe
    end
  end
  
  def quest_statistic_entries(quest)
    statistic_entries = []
    statistic_entries << if quest.active?
      [
        dt(Quest.human_attribute_name(:bounty)),
        dd(quest.bounty.to_s(:cents => false)),
        dt(Quest.human_attribute_name(:forwards)),
        dd(quest.forwards.count),
        dt(Quest.human_attribute_name(:offers)),
        dd(quest.offers.count)
      ] 
    elsif quest.expired?
      [
        dt(I18n.t("quest.status.expired")),
        dd("")
      ]
    elsif !quest.started?
      [
        dt(I18n.t("quest.status.not_started")),
        dd("")
      ]
    end
    
    statistic_entries.flatten
  end
  
end

__END__
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

    header_button(:stop, url_for(:controller => :runs, :action => :cancel, :id => quest))
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
