module NavigationHelper
  # returns "active" if the nav_item belongs to the current controller.
  def navigation_item_class_for(nav_item)
    if controller.class.name.gsub("Controller","").downcase == nav_item
      "active"
    end
  end

  ADMIN_NAVIGATION = {
    "stats" => "https://www.stathat.com/home",
    "logs"  => "https://papertrailapp.com/systems/staging/events"
  }
  
  def link_to_nav_item(nav_item)
    expect! nav_item => String
    
    if admin_only_url = ADMIN_NAVIGATION[nav_item]
      link_to I18n.t("nav.#{nav_item}"), admin_only_url, :target => "_blank"
    else
      link_to I18n.t("nav.#{nav_item}"), send("#{nav_item}_path")
    end
  end
  
  def nav_items
    nav_items = []
    nav_items << "quests"
    if current_user && (current_user.offers.first || current_user.quests.first)
      nav_items << "offers"
    end
    nav_items += ADMIN_NAVIGATION.keys if admin?
    nav_items
  end
end
