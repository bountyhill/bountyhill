class StaticController < ApplicationController
  layout :layout

  def layout #:nodoc:
    "static"
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
