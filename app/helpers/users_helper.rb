module UsersHelper
  def profile_box(user)
    expect! user => User
    
    title = user.name
    title += " #{span(user.twitter_handle, :class => 'handle')}" if user.twitter_handle

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
    image_tag url, :alt => user.name, :title => user.name, :class => "avatar #{options[:class]}", :width => size, :height => size
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
  
end
__END__

  def link_to_twitter(user, options = {})
    if twitter_handle = user.twitter_handle
      link_to twitter_handle, "https://twitter.com/#{twitter_handle[1..-1]}", options
    end
  end

end
