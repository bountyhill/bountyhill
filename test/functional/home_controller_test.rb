# encoding: UTF-8

require_relative "../test_helper.rb"

class HomeControllerTest < ActionController::TestCase

  def setup
    @controller = HomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template "index"
  end
end