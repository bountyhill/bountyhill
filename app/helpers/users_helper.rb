module UsersHelper
  AVATAR_SIZE = 96
  
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_for(user)
    avatar_url = user.avatar :default => "#{root_url}/#{image_path("default_avatar.png")}", :size => AVATAR_SIZE
    image_tag(avatar_url, alt: user.name, class: "avatar")
  end
end
