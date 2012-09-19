module UsersHelper
  AVATAR_SIZE = 128
  
  def default_avatar
    File.join(root_url, asset_path("default_avatar_128.png"))
  end
  
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def avatar(user, options = {})
    size = options[:size] ||= AVATAR_SIZE
    default = options[:default] || default_avatar
    
    url = user.avatar(:size => size, :default => default)
    image_tag url, alt: user.name, title: user.name, class: "avatar", 
                 width: size, height: size
  end

  def link_to_twitter_account(user)
    if twitter_handle = user.twitter_handle
      link_to twitter_handle, "https://twitter.com/#{twitter_handle[1..-1]}"
    end
  end
end
