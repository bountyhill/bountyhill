# encoding: UTF-8

require_relative "../test_helper.rb"

class ErrorsControllerTest < ActionController::TestCase

  def setup
    @controller = ErrorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_not_found
    # format html
    get :not_found
    assert_response :not_found
    assert_template "show"
    assert_equal    "not_found", assigns(:error)

    # format png
    get :not_found, :format => 'png'
    assert_response :not_found
    assert_equal    "Not Found", @response.body
    assert_equal    "not_found", assigns(:error)
  end
  
  def test_unprocessable_entity
    # format html
    get :unprocessable_entity
    assert_response :unprocessable_entity
    assert_template "show"
    assert_equal    "unprocessable_entity", assigns(:error)

    # format css
    get :unprocessable_entity, :format => 'css'
    assert_response :unprocessable_entity
    assert_equal    "Unprocessable Entity", @response.body
    assert_equal    "unprocessable_entity", assigns(:error)
  end

  def test_internal_server_error
    # format html
    get :internal_server_error
    assert_response :internal_server_error
    assert_template "show"
    assert_equal    "internal_server_error", assigns(:error)

    # format xml
    get :internal_server_error, :format => 'xml'
    assert_response :internal_server_error
    assert_equal    "Internal Server Error", @response.body
    assert_equal    "internal_server_error", assigns(:error)
  end
  
end
