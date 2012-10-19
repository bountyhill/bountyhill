# encoding: utf-8

module NavigationHelper
  # returns "active" if the nav_item belongs to the current controller.
  def navigation_item_active?(nav_item)
    # some navigation items takes precendence over others when determining
    # the active navigation item. For example, "/quests?owner_id=123" is
    # *your_quests* and not *quests*.
    @static_active_navigation_item ||= begin
      user_id = current_user.id if current_user
      
      if request.path =~ /^\/profile/
        :profile
      elsif controller_name == "offers" && params[:owner_id] == user_id.to_s
        :your_offers
      elsif controller_name == "offers"
        :offers
      elsif controller_name == "quests" && params[:owner_id] == user_id.to_s
        :your_quests
      elsif controller_name == "quests"
        :quests
      else
        :none
      end
    end

    if @static_active_navigation_item != :none
      nav_item == @static_active_navigation_item
    else
      request.path.starts_with?("/#{nav_item}")
    end
  end

  ADMIN_NAVIGATION = {
    :stats => "https://www.stathat.com/home",
    :logs  => "https://papertrailapp.com/systems/#{Bountybase.environment}/events",
    :jobs  => "/jobs"
  }
  
  def nav_profile_label
    info = span(" &#10003;") if current_user && current_user.identity(:confirmed, :twitter)
    "#{h current_user.name}#{info}".html_safe
  end

  def link_to_nav_item(nav_item)
    expect! nav_item => [Symbol]

    case nav_item
    when :dot
      link_to "·", "#", :class => "separator"
    when :profile
      link_to nav_profile_label, "/profile"
    when :your_offers
      link_to I18n.t("nav.#{nav_item}"), offers_path(:owner_id => current_user.id)
    when :your_quests
      link_to I18n.t("nav.#{nav_item}"), quests_path(:owner_id => current_user.id)
    when :copyright
      link_to "&copy; bountyhill, 2012".html_safe, contact_path
    when :signout
      link_to I18n.t("nav.#{nav_item}"), send("#{nav_item}_path"), :method => "delete"
    when *ADMIN_NAVIGATION.keys
      link_to I18n.t("nav.#{nav_item}"), ADMIN_NAVIGATION[nav_item], :target => "_blank"
    else
      link_to I18n.t("nav.#{nav_item}"), send("#{nav_item}_path")
    end
  end
  
  def navigation_items(position)
    expect! position => [:left, :right, :bottom_left, :bottom_right]
    
    case position
    when :left
      nav_items = [ :about, :quests ]
      if current_user && current_user.identity?(:email)
        nav_items.concat [ :dot, :your_quests, :your_offers ]
      end
      nav_items
    when :right
      if current_user
        [ :profile, :signout ]
      else
        [ :signin ]
      end
    when :bottom_left
      [ :terms, :privacy, :contact ]
    when :bottom_right
      if admin?
        ADMIN_NAVIGATION.keys + [ :copyright ]
      else
        [ :copyright ]
      end
    end
  end
  
  def render_navigation_items(position)
    show_active_links = position == :right || position == :left
    
    ul :class => "nav #{" pull-right" if position == :right || position == :bottom_right }" do
      navigation_items(position).map do |navigation_item|
        if link = link_to_nav_item(navigation_item)
          css = {}
          if show_active_links && navigation_item_active?(navigation_item)
            css = { :class => "active" }
          end
          
          content_tag :li, link, css
        end
      end.compact.join.html_safe
    end
  end
end
