module UsersHelper

    # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_for(user)
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "http://gravatar.com/avatar/#{gravatar_id}.png?d=#{default_image_url}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

  def default_image_url
    root_url + image_path("default_avatar.png")
  end

end
