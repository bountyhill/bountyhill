module UsersHelper
  AVATAR_SIZE = 128
  
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def avatar(user, options = {})
    size = options[:size] ||= AVATAR_SIZE
    
    url = user.avatar(:size => size)
    image_tag url, :alt => user.name, :title => user.name, :class => "avatar #{options[:class]}", :width => size, :height => size
  end
  
  def profile_box(user)
    expect! user => User
    
    title = user.name
    title += " #{span(user.twitter_handle, :class => 'handle')}" if user.twitter_handle

    box(:user, user, :title => title || I18n.t("user.box.title"))
  end
  
  def user_buttons(user)
    expect! user => User
    
    ul :class => "interactions" do
      [
        delete_user_button(user),
        change_password_button(user),
        edit_user_button(user),
        follow_user_button(user)
      ].compact.map{|button| li(button)}.join.html_safe
    end
  end

  def delete_user_button(user)
    return unless personal_page?
    
    modal_link_to(awesome_icon(:icon_ban_circle) + content_tag(:span, t("button.delete")),
      { :controller => :users, :action  => :delete, :id => user.id },
      :title => t("button.delete"), :rel => "nofollow")
  end

  def change_password_button(user)
    return 
    
    #TODO: proper controller action missing!
    
    return unless personal_page?
    
    modal_link_to(awesome_icon(:icon_lock) + content_tag(:span, t("button.change")),
    { :controller => :users, :action  => :change, :id => user.id },
      :title => t("button.change"), :rel => "nofollow")
  end
  
  def edit_user_button(user)
    return unless personal_page?

    modal_link_to(awesome_icon(:icon_edit) + content_tag(:span, t("button.edit")),
      edit_user_path(user),
      :title => t("button.edit"), :rel => "nofollow")
  end
  
  def follow_user_button(user)
    return if personal_page? || user.identities(:twitter).blank?
    
    link_to(awesome_icon(:icon_twitter) + content_tag(:span, t("button.follow")),
      url_for_follow_twitter_account(:account => user.twitter_handle),
      :target => :blank, :title => t("button.follow"), :rel => "nofollow")
  end
  
end
__END__

  def link_to_twitter(user, options = {})
    if twitter_handle = user.twitter_handle
      link_to twitter_handle, "https://twitter.com/#{twitter_handle[1..-1]}", options
    end
  end

end
