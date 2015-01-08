# encoding: UTF-8

module NavigationHelper
  # returns "active" if the nav_item belongs to the current controller.
  def navigation_item_active?(nav_item)
    # some navigation items takes precendence over others when determining
    # the active navigation item. For example, "/quests?owner_id=123" is
    # *my_quests* and not *quests*.
    @static_active_navigation_item ||= begin      
      if request.path =~ /^\/profile/
        :profile
      elsif controller_name == "offers" && personal_page?
        :my_offers
      elsif controller_name == "offers"
        :received_offers
      elsif controller_name == "quests" && personal_page?
        :my_quests
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
      link_to awesome_icon(icon_for('navigation.start_quest')) + span(I18n.t("nav.start_quest")), new_quest_path
    when :quests
      link_to awesome_icon(icon_for('navigation.quests')) + span(I18n.t("nav.quests")), quests_path
    when :my_quests
      link_to awesome_icon(icon_for('navigation.my_quests')) + I18n.t("nav.my_quests"), :controller => :quests, :owner_id => current_user
    when :my_offers
      link_to awesome_icon(icon_for('navigation.my_offers')) + I18n.t("nav.my_offers"), :controller => :offers, :owner_id => current_user
    when :received_offers
      link_to awesome_icon(icon_for('navigation.received_offers')) + I18n.t("nav.received_offers"), offers_path
    when :profile
      link_to awesome_icon(icon_for('navigation.my_profile')) + I18n.t("nav.my_profile"), "/profile"
    when :signout
      link_to awesome_icon(icon_for('navigation.signout')) +  span(I18n.t("nav.signout")), signout_path, :method => :delete
    when :copyright
      link_to "<strong>&copy; bountyhill, #{Time.now.year}</strong>".html_safe, root_path
    when :signin
      modal_link_to awesome_icon(icon_for('navigation.signin')) + span(I18n.t("nav.signin")), signin_path
    when *ADMIN_NAVIGATION.keys
      link_to I18n.t("nav.#{nav_item}"), ADMIN_NAVIGATION[nav_item], :target => "_blank"
    when :twitter
      link_to(awesome_icon(icon_for('navigation.twitter')), 
        Bountybase.config.twitter_app["page_url"], :target => :blank)   unless Bountybase.config.twitter_app["page_url"].blank?
    when :facebook
      link_to(awesome_icon(icon_for('navigation.facebook')),
        Bountybase.config.facebook_app["page_url"], :target => :blank)  unless Bountybase.config.facebook_app["page_url"].blank?
    when :google
      link_to(awesome_icon(icon_for('navigation.google')),
        Bountybase.config.google_app["page_url"], :target => :blank)    unless Bountybase.config.google_app["page_url"].blank?
    when :linkedin
      link_to(awesome_icon(icon_for('navigation.linkedin')),
        Bountybase.config.linkedin_app["page_url"], :target => :blank)  unless Bountybase.config.linkedin_app["page_url"].blank?
    when :xing
      link_to(awesome_icon(icon_for('navigation.xing')),
        Bountybase.config.xing_app["page_url"], :target => :blank)      unless Bountybase.config.xing_app["page_url"].blank?
    when :divider
      ""
    else
      link_to I18n.t("nav.#{nav_item}"), send("#{nav_item}_path")
    end
  end
  
  def navigation_items(position)
    expect! position => [:header_center, :user, :footer_left, :footer_right]
    
    case position
    when :user
      [ :my_quests, :my_offers, :received_offers, :profile, :divider, :signout ]
    when :header_center
      [ :start_quest, :quests ]
    when :footer_right
      [:twitter, :facebook, :google, :linkedin, :xing] + [ :copyright ]
    when :footer_left
      [ :faq, :contact, :imprint, :terms, :privacy ]
    end
  end
  
  def render_navigation_items(position = :header_center)
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
      ul :class => "nav nav-user" do
        content_tag :li, :class => "dropdown" do
            user_dropdown_menu
        end
      end
    else
      ul :class => "nav nav-login" do
        navigation_item(:signin)
      end
    end
  end
  
  def user_dropdown_menu
    return unless user = current_user

    avatar_size = 48
    img = image_tag user.avatar(:size => avatar_size),
     :alt => user.name,
     :class => "avatar",
     :height => avatar_size
    ident = div :class => "user-ident" do
      div(user.name || '&nbsp;', :class => "name")
    end
    
    link_to(ident + img, "#", :class => "dropdown-toggle", :"data-toggle" => "dropdown") + 
    ul(:class => "dropdown-menu", :role => "menu") do
      navigation_items(:user).map do |nav_item|
        navigation_item(nav_item)
      end.compact.join.html_safe
    end
  end
end
