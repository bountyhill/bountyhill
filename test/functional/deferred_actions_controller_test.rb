# encoding: UTF-8

require_relative "../test_helper.rb"

class DeferredActionsControllerTest < ActionController::TestCase

  def setup
    @controller = DeferredActionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    
    @user = Factory(:user)
    login @user
  end
  
  def test_not_performable
    action = DeferredAction.create!(:actor => @user, :action => "reset_password")
    # TODO: action.expects(:performable?).once.returns(false)
    DeferredAction.any_instance.expects(:performable?).once.returns(false)
    
    get :show, :id => action.secret
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal action, assigns(:action)
    assert_equal I18n.t("notice.action.invalid"), flash[:error]
  end
  
  def test_confirm
    UserMailer.expects(:confirm_email).with(@user)
    Deferred.expects(:mail).once
    
    post :confirm
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.email.confirmation.sent"), flash[:success]
  end
  
  def test_confirm_email
    action = DeferredAction.create!(:actor => @user, :action => "confirm_email")
    get :show, :id => action.secret
    
    assert_equal action, assigns(:action)
    assert_equal I18n.t("sessions.email.confirmed"), flash[:success]
  end
  
  def test_reset_password
    action = DeferredAction.create!(:actor => @user, :action => "reset_password")
    get :show, :id => action.secret

    assert_equal action, assigns(:action)
  end
  
  def test_unknown_method
    {
      :show     => %w(post put delete),
      :confirm  => %w(get put delete)
    }.each do |action, methods|
      methods.each do |method|
        self.send(method, action)
        assert_response :redirect
        assert_redirected_to root_path
        assert_equal I18n.t("notice.method.invalid"), flash[:error]
      end
    end
  end
end