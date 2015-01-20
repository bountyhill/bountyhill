# encoding: UTF-8

module UsersHelper
  def profile_box(user, options={})
    expect! user => User
    
    title =   if user.commercial? then  identity_icon(:commercial, :title => I18n.t("user.box.profile.icon.commercial"))
              else                      identity_icon(:private,    :title => I18n.t("user.box.profile.icon.private"))
              end
    title +=  if current_user == user then  I18n.t("user.box.title")
              else                          I18n.t("user.box.profile.title")
              end
    box(:user, user, { :title => title }.merge(options))
  end
  
  def identity_box(user, identity_type)
    return unless current_user == user

    title =   identity_icon(identity_type)
    title +=  I18n.t("user.box.#{identity_type}.title")
    box(identity_type, user.identity(identity_type), :title => title, :class => "with-opener")
  end
  
  def activities_box(user, options={})
    expect! user => User

    @activities = user.activities.paginate(
      :page     => options[:page] ||= 1,
      :per_page => options[:per_page],
      :group    => 'activities.id',
      :order    => "created_at DESC",
      :include  => :user)

    list_box(:activities, @activities, :title => I18n.t("user.box.activities.title"), :class => "with-opener")
  end

  def user_buttons(user)
    expect! user => User
    
    button_group [
      edit_user_button(user),
      follow_user_button(user)
    ]
  end

  def edit_user_button(user)
    return unless personal_page?

    modal_awesome_button(icon_for('interaction.edit'), edit_user_path(user)) { I18n.t("button.edit") }
  end
  
  def follow_user_button(user)
    return if personal_page? 
    return unless user.identities(:twitter).present?

    awesome_button(icon_for('interaction.follow'), url_for_follow_twitter_account(:account => user.twitter_handle),
      :html => { :target => :blank, :rel => "nofollow" }) { I18n.t("button.follow") }
  end
  
  # def email_buttons(identity)
  # def twitter_buttons(identity)
  # def facebook_buttons(identity)
  # def google_buttons(identity)
  # def linkedin_buttons(identity)
  # def xing_buttons(identity)
  [:email, :twitter, :facebook, :google, :linkedin, :xing].each do |i|
    define_method("#{i}_buttons") do |identity|
      button_group [identity_button(identity, i)]
    end
  end
  
  def address_buttons(identity)
    button_group [
      identity_button(identity, :address), #, :delete => false),
      edit_address_button(identity)
    ]
  end

  def edit_address_button(identity)
    return unless personal_page?
    return unless identity

    modal_awesome_button(icon_for('interaction.edit'), edit_identity_path(identity)) { I18n.t("button.edit") }
  end
  
  def identity_button(identity, type, options={})
    expect! identity => [nil, Identity]
    expect! type     => Symbol
    
    if identity.nil?
      modal_awesome_button(icon_for("identity.#{type}"), new_identity_path(:provider => type))  { I18n.t("button.provide") } if (options[:new] != false)
    else
      modal_awesome_button(icon_for('interaction.delete'), delete_identity_path(identity)) { I18n.t("button.remove") } if (options[:delete] != false) && !identity.solitary?
    end
  end
  
  def avatar(user, options = {})
    expect! user => [nil, User]
    size = options[:size] ||= 128
    
    user ||= User.draft
    url = user.avatar(:size => size)

    image_tag url, 
      :alt              => user.name,
      :class            => "avatar #{options[:class]}",
      :height           => size,
      :title            => user.name,
      :"data-toggle"    => "tooltip",
      :"data-placement" => "bottom"
  end
  
  def user_bar(user, type, options={})
    expect! type => [:quest, :offer]
    
    avatar_size = 64
    link_to user_path(user), :class => "user bar #{type} #{options[:class]}" do
      div(
        [
          div(avatar(user, :size => avatar_size), :class => "image-container"),
          div(user.name, :class => "name")
        ].join.html_safe, :class => "profile") + 
        user_points(user)
    end
  end
  
  def user_points(user)
    div :class => "rating" do
      [
        user_stars(user),
        div(user.points, :class => "points"),
        div(I18n.t("user.statistic.points", :count => user.points), :class => "text")
      ].join.html_safe
    end
  end
  
  def user_stars(user)
    ul :class => "stars" do
      user.score.times.map{ li(awesome_icon(:star)) }.join.html_safe
    end
  end
  
  def user_statistic_boxes(user)
    [
      # user_points_statistic_box(user),
      user_quests_statistic_box(user),
      user_offers_statistic_box(user),
      user_forwards_statistic_box(user)
    ].compact.map{ |box| box + spacer }.join.html_safe
  end
  
  def user_points_statistic_box(user)
    statistic_box user.points,
      I18n.t("user.statistic.points", :count => user.points),
      user_stars(user), :css_class => "user"
  end
  
  def user_quests_statistic_box(user)
    statistic_box user.quests.size,
      I18n.t("user.statistic.quests", :count => user.quests.size),
      awesome_icon(icon_for('status.quests')), :css_class => "user"
  end
  
  def user_offers_statistic_box(user)
    statistic_box user.offers.size,
      I18n.t("user.statistic.offers", :count => user.offers.size),
      awesome_icon(icon_for('status.offers')), :css_class => "user"
  end

  def user_forwards_statistic_box(user)
    statistic_box user.forwards.size,
      I18n.t("user.statistic.forwards", :count => user.forwards.size),
      awesome_icon(icon_for('status.forwards')), :css_class => "user"
  end

  def identity_icon(identity, options={})
    div(:class => :"identity-icon") do
      link_to(awesome_icon(icon_for("identity.#{identity}")), "#",
        :id               => "identity-icon-#{identity}",
        :"data-toggle"    => "tooltip",
        :"data-placement" => "right",
        :title            => options[:title] || I18n.t("user.box.#{identity}.icon"))
    end + javascript_tag("$('#identity-icon-#{identity}').tooltip();")
  end

  def privacy_icon(identity)
    div(:class => :"privacy-icon") do
      link_to(awesome_icon(:eye_slash), "#",
        :id               => "privacy-icon-#{identity}",
        :"data-toggle"    => "tooltip",
        :"data-placement" => "left",
        :title            => I18n.t("icon.privacy"))
    end + javascript_tag("$('#privacy-icon-#{identity}').tooltip();")
  end
  
end
