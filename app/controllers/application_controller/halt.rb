# encoding: UTF-8

# ApplicationController::Halt adds a halt! method which halts the current
# action, and render! and redirect_to! methods based on halt!, that work
# like their non-bang counterparts but stop the action upon invocation.
module ApplicationController::Halt

  def self.included(klass)
    klass.rescue_from HaltCondition, :with => :halted
  end

  # halt! raises the HaltCondition, which leaves the current action
  # and ends up in the halted no-op method.
  class HaltCondition < RuntimeError; end

  private
  
  def redirect_to!(*args)
    redirect_to *args
    halt!
  end

  def render!(*args)
    render *args
    halt!
  end
  
  def halt!
    raise HaltCondition
  end
  
  def halted
  end
end
