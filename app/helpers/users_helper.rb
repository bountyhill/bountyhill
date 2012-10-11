module UsersHelper
  AVATAR_SIZE = 128
  
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def avatar(user, options = {})
    size = options[:size] ||= AVATAR_SIZE
    
    url = user.avatar(:size => size)
    image_tag url, alt: user.name, title: user.name, class: "avatar", 
                 width: size, height: size
  end

  def link_to_twitter_account(user)
    if twitter_handle = user.twitter_handle
      link_to twitter_handle, "https://twitter.com/#{twitter_handle[1..-1]}"
    end
  end
  
  def render_tabs
    default_tab = current_tabs.first
    
    ul :class => "nav nav-tabs" do
      current_tabs.map do |tab|
        li :class => ("active" if active_tab == tab) do
          url = tab == default_tab ? "/profile" : "/profile/#{tab}"
          link_to I18n.t("users.tab.#{tab}"), url
        end
      end.join.html_safe
    end
    
  end
end
