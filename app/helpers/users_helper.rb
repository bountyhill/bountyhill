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
  
  def render_sections(user)
    scope = personal_page? ? "private" : "public"
    %w(card).map do |section|
      div :id => section, :class => "section" do
        partial "users/show/#{scope}/#{section}", :user => user
      end
    end.join.html_safe
  end
    
  def render_stats_note(options={})
    li :class => options[:html_class] do
      small(options[:title]) +
      p("#{strong(options[:count])} #{options[:subtitle]}")
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
