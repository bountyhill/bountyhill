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
    expect! nav_item => [String, :profile, :signout, :copyright]
    
    if nav_item == :profile
      link_to current_user.name, "/profile"
    elsif nav_item == :copyright
      link_to "&copy; bountyhill, 2012".html_safe, contact_path
    elsif nav_item == :signout
      link_to I18n.t("nav.#{nav_item}"), send("#{nav_item}_path"), :method => "delete"
    elsif admin_only_url = ADMIN_NAVIGATION[nav_item]
      link_to I18n.t("nav.#{nav_item}"), admin_only_url, :target => "_blank"
    else
      link_to I18n.t("nav.#{nav_item}"), send("#{nav_item}_path")
    end
  end
  
  def navigation_items(position)
    expect! position => [:left, :right, :bottom_left, :bottom_right]
    
    case position
    when :left
      nav_items = [ "about", "quests" ]
      if current_user && (current_user.offers.first || current_user.quests.first)
        nav_items << "offers"
      end
      nav_items
    when :right
      if current_user
        [ :profile, :signout ]
      else
        [ "signup", "signin" ]
      end
    when :bottom_left
      [ "terms", "privacy", "contact" ]
    when :bottom_right
      if admin?
        ADMIN_NAVIGATION.keys + [ :copyright ]
      else
        [ :copyright ]
      end
    end
  end
  
  def render_navigation_items(position)
    ul :class => "nav #{" pull-right" if position == :right || position == :bottom_right }" do
      navigation_items(position).map do |navigation_item|
        if link = link_to_nav_item(navigation_item)
          content_tag :li, link, :class => navigation_item_class_for(navigation_item)
        end
      end.compact.join.html_safe
    end
  end
end
