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
  
end
__END__

  def link_to_twitter(user, options = {})
    if twitter_handle = user.twitter_handle
      link_to twitter_handle, "https://twitter.com/#{twitter_handle[1..-1]}", options
    end
  end

end
