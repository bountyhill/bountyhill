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
      elsif controller_name == "offers" && personal_page?
        :your_offers
      elsif controller_name == "offers"
        :offers
      elsif controller_name == "quests" && personal_page?
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

  def link_to_nav_item(nav_item)
    expect! nav_item => [Symbol]

    case nav_item
    when :start_quest
      modal_link_to awesome_icon(:edit) + span(I18n.t("nav.start_quest")), new_quest_path
    when :quests
      link_to awesome_icon(:list) + span(I18n.t("nav.quests")), quests_path
    when :your_quests
      link_to awesome_icon(:list) + I18n.t("nav.your_quests"), quests_path(:owner_id => current_user.id)
    when :your_offers
      link_to awesome_icon(:th_list) + I18n.t("nav.your_offers"), offers_path(:owner_id => current_user.id)
    when :profile
      link_to awesome_icon(:user) + I18n.t("nav.your_profile"), "/profile"
    when :signout
      link_to awesome_icon(:signout) +  I18n.t("nav.signout"), signout_path, :method => :delete
    when :divider
      ""
    when :copyright
      link_to "<strong>&copy; bountyhill, #{Time.now.year}</strong>".html_safe, root_path
    when :signin
      modal_link_to awesome_icon(:signin) + I18n.t("nav.signin"), signin_path
    when *ADMIN_NAVIGATION.keys
      link_to I18n.t("nav.#{nav_item}"), ADMIN_NAVIGATION[nav_item], :target => "_blank"
    else
      link_to I18n.t("nav.#{nav_item}"), send("#{nav_item}_path")
    end
  end
  
  def navigation_items(position)
    expect! position => [:header_center, :user, :footer_left, :footer_right]
    
    case position
    when :user
      [ :your_quests, :your_offers, :profile, :divider, :signout ]
    when :header_center
      [ :start_quest, :quests ]
    when :footer_right
      (admin? ? ADMIN_NAVIGATION.keys : []) + [ :copyright ]
    when :footer_left
      [ :about, :contact, :imprint, :terms, :privacy ]
    end
  end
  
  def render_navigation_items(position)
    show_active_links = position == :header_center
    css = ""
    css += " nav-main"    if position == :header_center
    css += " pull-right"  if position =~ /right/
    
    ul :class => "nav #{css}", :role => "menu" do
      navigation_items(position).map do |nav_item|
        navigation_item(nav_item)
      end.compact.join.html_safe
    end
  end
  
  def navigation_item(nav_item)
    if link = link_to_nav_item(nav_item)
      css = { :role => "menuitem"}
      css[:class] = "active"  if navigation_item_active?(nav_item)
      css[:class] = "divider" if nav_item == :divider
      
      content_tag :li, link, css
    end
  end
  
  def user_navigation
    if current_user
      ul :class => "nav nav-user pull-right" do
        content_tag :li, :class => "dropdown" do
            user_dropdown_menu
        end
      end
    else
      ul :class => "nav pull-right" do
        navigation_item(:signin)
      end
    end
  end
  
  def user_dropdown_menu
    return unless user = current_user

    avatar_size = 40
    img = image_tag user.avatar(:size => avatar_size),
     :alt => user.name,
     :class => "avatar",
     :width => avatar_size,
     :height => avatar_size
    ident = div :class => "user-ident" do
      div(user.name, :class => "name") + 
      div(user.twitter_handle, :class => "handle")
    end
    
    link_to(ident + img, "#", :class => "dropdown-toggle", :"data-toggle" => "dropdown") + 
    ul(:class => "dropdown-menu", :role => "menu") do
      navigation_items(:user).map do |nav_item|
        navigation_item(nav_item)
      end.compact.join.html_safe
    end
  end
end
