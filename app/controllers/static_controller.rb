class StaticController < ApplicationController
  def home
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
