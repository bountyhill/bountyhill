class StaticController < ApplicationController
  # The static layout wraps a single, 12 column spanning row
  # into the general application layout. 
  layout "static"
  
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
end
