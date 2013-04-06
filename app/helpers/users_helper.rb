module UsersHelper
  def profile_box(user)
    expect! user => User
    
    if @current_user == user
      title = I18n.t("user.box.title")
    else
      title = user.name
      title += " #{span(user.twitter_handle, :class => 'handle')}" if user.twitter_handle
    end
    box(:user, user, :title => title || I18n.t("user.box.profile.title"))
  end
  
  def activities_box(user, options={})
    expect! user => User

    @activities = user.activities.paginate(
      :page     => options[:page],
      :per_page => options[:per_page],
      :order    => "created_at DESC",
      :include  => :user)

    list_box(:activities, @activities, :title => I18n.t("user.box.activities.title"), :class => "with-opener")
  end

  def activities_list_box_buttons
    # nothing to do here
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

    modal_awesome_button(:pencil, edit_user_path(user)) { I18n.t("button.edit") }
  end
  
  def follow_user_button(user)
    return if personal_page? || user.identities(:twitter).blank?

    awesome_button(:twitter, url_for_follow_twitter_account(:account => user.twitter_handle),
      :html => { :target => :blank, :rel => "nofollow" }) { I18n.t("button.follow") }
  end
  
  def avatar(user, options = {})
    expect! user => User
    size = options[:size] ||= 128
    
    url = user.avatar(:size => size)
    image_tag url, 
      :alt              => user.name,
      :class            => "avatar #{options[:class]}",
      :width            => size,
      :height           => size,
      :title            => "#{strong(user.name)}<br>#{user.twitter_handle}",
      :"data-toggle"    => "tooltip",
      :"data-placement" => "bottom"
  end
  
  def user_bar(user, type)
    expect! type => [:quest, :offer]
    
    link_to user_path(user), :class => "user bar #{type}" do
      div(
        [
          avatar(user, :size => 64),
          div(user.name, :class => "name"),
          div(user.twitter_handle, :class => "handle")
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
      user_points_statistic_box(user),
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
      awesome_icon(:edit, :size => :large), :css_class => "user"
  end
  
  def user_offers_statistic_box(user)
    statistic_box user.offers.size,
      I18n.t("user.statistic.offers", :count => user.offers.size),
      awesome_icon(:share, :size => :large), :css_class => "user"
  end

  def user_forwards_statistic_box(user)
    statistic_box user.forwards.size,
      I18n.t("user.statistic.forwards", :count => user.forwards.size),
      awesome_icon(:retweet, :size => :large), :css_class => "user"
  end
  
  CONTACT_INFO_FIELDS = %w(name email phone twitter facebook)
  def user_contact_info(user)
    dl do
      CONTACT_INFO_FIELDS.map do |attribute|
        next unless (contact_info = user.send(attribute)).present?
        dt(User.human_attribute_name(attribute)) +
        dd(contact_info)
      end.compact.join.html_safe
    end
  end

  def user_address_info(user)
    return unless (address_info = user.address).present?
    dl do
      dt(User.human_attribute_name(:address1)) +
      dd(address_info.join("<br>").html_safe)
    end
  end
  
end
__END__

  def link_to_twitter(user, options = {})
    if twitter_handle = user.twitter_handle
      link_to twitter_handle, "https://twitter.com/#{twitter_handle[1..-1]}", options
    end
  end

end
