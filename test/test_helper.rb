# encoding: UTF-8

require 'simplecov'
require 'rubygems'
require 'spork'

#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

end

Spork.each_run do
  # This code will be run each time you run your specs.

end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.




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

require_relative "access_control_assertions"
require_relative "activity_assertions"

class ActiveSupport::TestCase
  include AccessControlAssertions
  include ActivityAssertions
  
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def self.admin
    @admin ||= Identity::Twitter.find_by_identifier("radiospiel").user
  end
  
  def admin
    @admin ||= ActiveSupport::TestCase.admin
  end
  
  def setup
    ActiveRecord.current_user = admin
    User.stubs(:admin).returns(admin)
    
    # do not send anything to social networks in tests
    Koala::Facebook::API.any_instance.stubs(:put_connections)
    Twitter::Client.any_instance.stubs(:update)
  end

  def teardown
    ActiveRecord.current_user = nil
  end
  
  def login(user)
    # set given user as current user in controller
    @controller.instance_variable_set(:@current_user, user)
  end

  def logout
    login nil
  end

  def lorem_ipsum
    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, 
    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. 
    Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. 
    Lorem ipsum dolor sit amet, consetetur sadipscing elitr, 
    sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, 
    sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. 
    Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
  end

  # a identity "factory"
  def identity(name)
    name = name.to_s

    case name
    when /^@(.*)/
      Identity::Twitter.find_by_identifier($1) ||
        Identity::Twitter.create!(:identifier => $1)
    when /@/
      Identity::Email.find_by_email(name) ||
        Identity::Email.create!(:name => name, :email => name, :password => name, :password_confirmation => name)
    else
      Identity::Twitter.find_by_identifier(name) ||
        Identity::Twitter.create!(:identifier => name)
    end
  end

  # a user "factory"
  def user(name)
    identity(name).user
  end
  
  extend Forwardable
  delegate :as => ActiveRecord::AccessControl

  include ActiveRecord::Assertions
end

def Factory(*args)
  FactoryGirl.create(*args)
end
