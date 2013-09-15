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
    get :show
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
    assert_equal UsersController::FORM_PARTIALS, assigns(:partials)
    
    # test selective partial
    UsersController::FORM_PARTIALS.each do |partial|
      get :edit, :id => @user.id, partial => true
      assert_response :success
      assert_template :edit, :layout => 'dialog'
      assert_equal [partial], assigns(:partials)
    end
  end
  
  def test_access_not_allowed
    {
      :edit     => :get,
      :update   => :put,
      :destroy  => :delete
    }.each do |action, method|
      self.send(method, action, :id => @admin.id)
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal @admin, assigns(:user)
      assert_equal I18n.t("message.access.not_allowed"), flash[:error]
    end
  end
  
  def test_update
    # update user's profile
    put :update, :id => @user.id, :section => :profile, :user => { :first_name => "Hans", :last_name => "Wurst" }
    assert_response :redirect
    assert_redirected_to user_path(@user)
    assert_equal @user.reload, assigns(:user)
    assert_equal "Hans Wurst", @user.name
    assert_equal I18n.t("message.update.success", :record => @user.name), flash[:success]
  end
  
  def test_update_fails
    User.any_instance.expects(:save).once # TODO: @user.expects(:save).once
    # update user data
    put :update, :id => @user.id, :user => {}
    assert_response :success
    assert_equal @user, assigns(:user)
    assert assigns(:partials)
    assert_template :edit
  end

  def test_update_image
    image_url = "https://www.filepicker.io/api/file/ESqPbxGnQ6uqjVOuqt3S"
    
    # set image
    put :update, :id => @user.id, :section => :profile, :user => { :images => [image_url] }
    assert_response :redirect
    assert_redirected_to user_path(@user)
    assert_equal @user.reload, assigns(:user)
    assert_equal image_url, @user.image
    assert_equal I18n.t("message.update.success", :record => @user.name), flash[:success]
    
    # leave image untouched
    put :update, :id => @user.id, :section => :address, :user => { }
    assert_response :redirect
    assert_redirected_to user_path(@user)
    assert_equal @user.reload, assigns(:user)
    assert_equal image_url, @user.image
    assert_equal I18n.t("message.update.success", :record => @user.name), flash[:success]
    
    # delete image
    put :update, :id => @user.id, :section => :profile, :user => {}
    assert_response :redirect
    assert_redirected_to user_path(@user)
    assert_equal @user.reload, assigns(:user)
    assert_equal nil, @user.image
    assert_equal I18n.t("message.update.success", :record => @user.name), flash[:success]
  end
  
  def test_update_address
    put :update, :id => @user.id, :section => :address, :user => { :address1 => "Foo", :address2 => "Bar", :city => "FooBar" }
    assert_response :redirect
    assert_redirected_to user_path(@user)
    assert_equal @user.reload, assigns(:user)
    assert_equal "Foo", @user.address1
    assert_equal "Bar", @user.address2
    assert_equal "FooBar", @user.city
    assert_equal I18n.t("message.update.success", :record => @user.name), flash[:success]
  end

  def test_destroy
    User.any_instance.expects(:soft_delete!).once # TODO: @user.expects(:soft_delete!).once
    
    assert_no_difference "User.count" do
      delete :destroy, :id => @user.id, :user => { :delete_reason => "Foo Bar" }
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal @user.reload, assigns(:user)
      assert_equal "Foo Bar", @user.delete_reason
      assert_equal false, @controller.instance_variable_get(:@current_user)
    end
  end
  
end