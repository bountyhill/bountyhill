class StaticController < ApplicationController
  layout :layout, :except => "home"

  def layout #:nodoc:
    "page"
  end

  def home
  end

  def help
  end

  def about
  end

  def privacy
  end

  def terms
  end
  
  def contact
  end
end
