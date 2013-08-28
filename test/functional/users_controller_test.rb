# encoding: UTF-8

require_relative "../test_helper.rb"

class UsersControllerTest < ActionController::TestCase

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    
    # init common test objects
    @user = Factory(:user)
    login @user
  end
  
  def test_show
    # own profile
    get :show, :id => @user.id
    assert_response :success
    assert_template "show"
    assert_equal 24, assigns(:per_page)
    assert_equal @user, assigns(:user)
    
    # other profile
    get :show, :id => admin.id
    assert_response :success
    assert_template "show"
    assert_equal 24, assigns(:per_page)
    assert_equal admin, assigns(:user)
  end
  
  
  def test_edit
    # test all partials
    get :edit, :id => @user.id
    assert_response :success
    assert_template :edit, :layout => 'dialog'
    assert_equal UsersController::EDIT_PARTIALS, assigns(:partials)
    
    # test selective partial
    UsersController::EDIT_PARTIALS.each do |partial|
      get :edit, :id => @user.id, partial => true
      assert_response :success
      assert_template :edit, :layout => 'dialog'
      assert_equal [partial], assigns(:partials)
    end
  end
  
  def test_update
pend "TODO" do
    # update user itself
    put :update, :id => @user.id, :user => { :name => "Hans Wurst" }
    assert_response :success
    assert_template :show
    assert_equal @user.reload, assigns(:user)
    assert_equal "Hans Wurst", assigns(:user).name
end
  end

  def test_destroy
    User.any_instance.expects(:soft_delete!).once # TODO: @user.expects(:soft_delete!).once
    
    assert_no_difference "User.count" do
      delete :destroy, :id => @user.id, :user => { :delete_me => 1 }
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal false, @controller.instance_variable_get(:@current_user)
    end
  end
  
  def test_destroy_fails
    assert_no_difference "User.count" do
      delete :destroy, :id => @user.id
      assert_response :success
      assert_template :show
      assert_equal @user, assigns(:user)
      assert_equal I18n.t("message.check_delete_me"), assigns(:user).errors[:delete_me].first
    end
  end
  
end