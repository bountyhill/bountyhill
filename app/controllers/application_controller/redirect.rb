#
# ApplicationController::Redirected provides a redirect_to! method,
# which works like redirect_to, but stops the action at that point.
module ApplicationController::Redirected

  def self.included(klass)
    klass.rescue_from AfterRedirection, :with => :after_redirection
  end

  # The AfterRedirection is raised by redirect!
  class AfterRedirection < RuntimeError; end

  def redirect_to!(*args)
    redirect_to *args
    raise AfterRedirection
  end
  
  private
  
  def after_redirection
  end
end
