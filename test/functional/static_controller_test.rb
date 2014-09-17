# encoding: UTF-8

require_relative "../test_helper.rb"

class StaticControllerTest < ActionController::TestCase

  def setup
    @controller = StaticController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  %w(info contact imprint terms privacy).each do |static_page|
    define_method "test_#{static_page}" do
      get static_page
      assert_response :success
      assert_template static_page
    end
  end
end