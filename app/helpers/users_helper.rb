module UsersHelper
  AVATAR_SIZE = 128
  
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def avatar(user, options = {})
    size = options[:size] ||= AVATAR_SIZE
    
    url = user.avatar(:size => size)
    image_tag url, :alt => user.name, :title => user.name, :class => "avatar", :width => size, :height => size
  end

  def link_to_twitter_account(user)
    if twitter_handle = user.twitter_handle
      link_to twitter_handle, "https://twitter.com/#{twitter_handle[1..-1]}"
    end
  end

  def render_user_section(user, section)
    if section.in? ["card"] 
      partial_path = personal_page? ? "users/show/private/#{section}" : "users/show/public/#{section}"
    else
      partial_path = "users/show/#{section}"
    end
    
    div :id => section, :class => "section" do
      partial partial_path, :user => user
    end
  end
  
  def header_action_button_for_user(user)
    if personal_page?
      header_action(:user, edit_user_path(user), :title => t("user.actions.edit.title"), :text => t("user.actions.edit.sub"))
    elsif user.identities(:twitter)
      header_action(:twitter, 
        url_for_follow_twitter_account(:account => user.twitter_handle), 
        :title => t("user.actions.follow.title"),
        :text => t("user.actions.follow.sub"),
        :target => :blank
      )
    else
      ""
    end
  end
  
  def delete_user_button(user)
    return unless personal_page?
    header_button(:delete, url_for(:controller => :users, :action => :delete, :id => user.id))
  end
  
  def edit_user_button(user)
    return unless personal_page?
    header_button(:user, edit_user_path(user))
  end
  
  def follow_user_button(user)
    return if personal_page? || user.identities(:twitter).blank?
    header_button(:twitter, url_for_follow_twitter_account(:account => user.twitter_handle), :target => :blank)
  end
  
  # def active_tab
  #   params[:tab] || current_sections.first
  # end
  #
  # def render_tabs
  #   default_tab = current_tabs.first
  #   
  #   ul :class => "nav nav-tabs" do
  #     current_tabs.map do |tab|
  #       li :class => ("active" if active_tab == tab) do
  #         url = tab == default_tab ? "/profile" : "/profile/#{tab}"
  #         link_to I18n.t("users.tab.#{tab}"), url
  #       end
  #     end.join.html_safe
  #   end
  #   
  # end

end
