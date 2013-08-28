# encoding: UTF-8

require_relative "../test_helper.rb"

class ActivitiesControllerTest < ActionController::TestCase

  def setup
    @controller = ActivitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    
    # init common test objects
    @user     = Factory(:user)
    @activity = Factory(:activity, :user => @user)
    
    login @user
  end
  
  def test_index
    xhr :get, :index
    assert_response :success
    assert_template "index"
    assert_equal @user.activities.reverse, assigns(:activities)
  end
end