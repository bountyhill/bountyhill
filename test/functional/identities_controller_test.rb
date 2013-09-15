# encoding: UTF-8

require_relative "../test_helper.rb"

class IdentitiesControllerTest < ActionController::TestCase

  def setup
    @controller = IdentitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super

    @user = Factory(:twitter_identity).user
    login @user
  end

  def test_new
    post :new, :provider => 'twitter'
    assert_response :redirect
    assert_redirected_to "/auth/twitter"
  end

  def test_create
    # fails since no uid is given
    @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:twitter]
    post :create, :user => @user.id
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

end

__END__

  def test_destroy_fails
    # twitter is only identity of user
    assert_raises RuntimeError do
      assert_no_difference("Identity::Twitter.count") do
        delete :destroy, :id => @user.id
      end

      assert_equal :twitter, assigns(:identifier)
      assert_equal @user, assigns(:user)
      assert_equal @user.identity(:twitter), assigns(:identity)
      assert_redirected_to @user
    end
  end

  def test_destroy
    Factory(:email_identity, :user => @user)

    assert_difference("Identity::Twitter.count", -1) do
      delete :destroy, :id => @user.id
    end

    assert_equal :twitter, assigns(:identifier)
    assert_equal @user, assigns(:user)
    assert_equal @user.identity(:twitter), assigns(:identity)
    assert_response :redirect
    assert_redirected_to @user
  end
  
  # --- Email ---
  def test_update_email
    Factory(:email_identity, :user => @user)
    assert_not_equal "barfoo", @user.identity(:email).password

    put :update, :id => @user.id, :section => 'password', :identity => { 
      :password => @user.identity(:email).password,
      :password_new => "barfoo",
      :password_new_confirmation  => "barfoo"
    }
    assert_response :redirect
    assert_redirected_to user_path(@user)
    assert_equal "barfoo", assigns(:identity).password
    assert_equal I18n.t("message.update.success", :record => Identity::Email.human_attribute_name(:password)), flash[:success]
  end

  def test_update_fails
    Factory(:email_identity, :user => @user)

    put :update, :id => @user.id, :section => 'password', :identity => { :password => "" }
    assert_response :success
    assert_equal @user, assigns(:user)
    assert_not_equal "", assigns(:identity).password
    assert_template "edit"
  end

  def test_new_email
    Factory(:email_identity, :user => @user)

    # new is not allowed for identity email
    assert_raises RuntimeError do
      delete :destroy, :id => @user.id
    end
  end

  def test_destroy_email
    Factory(:email_identity, :user => @user)
    
    # destroy is not allowed for identity email
    assert_raises RuntimeError do
      delete :destroy, :id => @user.id
    end
  end

end