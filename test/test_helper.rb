ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'ruby-debug'

require 'test/unit'
require 'test/unit/ui/console/testrunner'   
require 'mocha'

class Test::Unit::UI::Console::TestRunner
  def guess_color_availability; true; end
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def self.admin
    @admin ||= Identity::Twitter.find_by_name("radiospiel").user
  end
  
  def admin
    @admin ||= ActiveSupport::TestCase.admin
  end
  
  def setup
    ActiveRecord::AccessControl.current_user = admin
  end

  def teardown
    ActiveRecord::AccessControl.current_user = nil
  end
end

def Factory(*args)
  FactoryGirl.create(*args)
end
