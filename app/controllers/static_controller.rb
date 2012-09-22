class StaticController < ApplicationController
  def home
    if current_user && (email = current_user.identity(:email)) && !email.confirmed?
      flash.now[:warn] = render_to_string(:partial => "confirm_reminder").html_safe
    end
  end

  def help
    set_layout :page
  end

  def about
    set_layout :page
  end

  def privacy
    set_layout :page
  end

  def terms
    set_layout :page
  end
end
