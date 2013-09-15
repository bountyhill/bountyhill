# encoding: UTF-8

require_relative "../test_helper.rb"

class IdentitiesControllerTest < ActionController::TestCase

  def setup
    @controller = IdentitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super

    @identity = Factory(:email_identity)
    @user = @identity.user
    login @user
  end

  # --- test Omniauth social identities actions ---------------------------------------------

  def test_new
    post :new, :provider => 'twitter'
    assert_response :redirect
    assert_redirected_to "/auth/twitter"
  end

  def test_create
    # fails since no uid is given
    @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:twitter]
    post :create
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.error"), flash[:error]
        
    # succeeds
    OmniAuth.config.add_mock(:twitter, {:provider => 'twitter'})
    @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:twitter]

    identity_twitter = Factory(:twitter_identity, :identifier => '12345')
    Identity::Twitter.expects(:find_or_create).once.returns(identity_twitter)
    identity_twitter.expects(:follow).once.returns(true)
    identity_twitter.expects(:direct_message).with(I18n.t("tweet.follow.success")).once
    @request.session[:follow_bountyhermes] = true
    
    post :create
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.success"), flash[:success]
  end

  def test_failure
    get :failure
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.failure"), flash[:error]
  end

  # --- test Email actions ---------------------------------------------
  
  def test_update_no_email
    identity = Factory(:twitter_identity, :user => @user)
    
    assert_raises RuntimeError do
      xhr :put, :update, :id => identity.id, :identity_twitter => { }
    end
  end
  
  def test_update_email
    assert_not_equal "barfoo", @user.identity(:email).password

    xhr :put, :update, :id => @identity.id, :identity_email => {
      :password_new => "barfoo",
      :password_new_confirmation  => "barfoo",
      :password => @identity.password
    }
pend "TODO: should be redirected to user - WTF!" do
    assert_response :redirect
    assert_redirected_to user_path(@user)
end
    assert assigns(:identity).valid?
    assert_equal "barfoo", assigns(:identity).password
    assert_equal I18n.t("message.update.success", :record => Identity::Email.human_attribute_name(:password)), flash[:success]
  end

  def test_update_email_fails
   # wrong password
   xhr :put, :update, :id => @identity.id, :identity_email => { :password => "foo bar" }
    assert_response :success
    assert_template "update"
    assert_equal @identity, assigns(:identity)
    assert assigns(:identity).errors[:password]
    assert_equal "identities/email" , assigns(:partial)

    # password_new and password_new_confirmation are unequal
    xhr :put, :update, :id => @identity.id, :identity_email => {
      :password_new => "barfoo",
      :password_new_confirmation  => "foobar",
      :password => @identity.password
    }
    assert_response :success
    assert_template "update"
    assert_equal @identity, assigns(:identity)
    assert assigns(:identity).errors[:password]
    assert_equal "identities/email" , assigns(:partial)
  end

  def test_destroy
    identity = Factory(:twitter_identity, :user => @user)
    assert_difference("Identity::Twitter.count", -1) do
      delete :destroy, :id => identity.id
    end
    assert_response :redirect
    assert_redirected_to user_path(@user)

    assert_equal @user, assigns(:user)
    assert !@user.reload.identity(:twitter)
  end

  def test_destroy_fails
    # email identity cannot be destroyed
    assert_raises RuntimeError do
      assert_no_difference("Identity::Email.count") do
        delete :destroy, :id => @identity.id
      end
    end
    
    # last identity of user cannot be destroyed
    identity = Factory(:twitter_identity, :user => @user)
    @identity.destroy
    assert_raises RuntimeError do
      assert_no_difference("Identity::Twitter.count") do
        delete :destroy, :id => identity.id
      end
    end
  end
  
end