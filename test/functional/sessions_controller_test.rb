# encoding: UTF-8

require_relative "../test_helper.rb"

class SessionsControllerTest < ActionController::TestCase

  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super

    logout
  end
  
  def test_signin_get
    # request signin
    get :signin_get
    assert_response :success
    assert_template 'new', :layout => 'dialog'
    assert_equal :signin, assigns(:mode)

    # request signup
    get :signin_get, :req => :signup
    assert_response :success
    assert_template 'new', :layout => 'dialog'
    assert_equal :signup, assigns(:mode)
    assert_equal :signup, @request.session[ApplicationController::RequiredIdentity::SESSION_KEY][:kind]
    assert_nil @request.session[ApplicationController::RequiredIdentity::SESSION_KEY][:on_success]
    assert_nil @request.session[ApplicationController::RequiredIdentity::SESSION_KEY][:on_cancel]
  end

  def test_signin_post_mode_signin
    identity = Factory(:email_identity)

    post :signin_post, :do_signin => true, :identity_email => { :email => identity.email, :password => identity.password }
    assert_response :redirect
    assert_redirected_to root_path
    assert !assigns(:identity).new_record?
    assert_equal :signin, assigns(:mode)
    assert_equal I18n.t("identity.form.success.signin", :name => assigns(:identity).name), flash[:success]
  end
    
  
  def test_signin_post_mode_reset
    identity = Factory(:email_identity)

    UserMailer.expects(:reset_password).once.with(identity.user).returns("foobar")
    Deferred.expects(:mail).once.with("foobar")
    
    post :signin_post, :do_reset => true, :identity_email => { :email => identity.email }
    assert_response :redirect
    assert_redirected_to root_path
    assert !assigns(:identity).new_record?
    assert_equal :reset, assigns(:mode)
    assert_equal I18n.t("identity.form.success.reset", :name => assigns(:identity).name), flash[:success]
  end

  def test_signin_post_mode_signup
    assert_difference("Identity::Email.count") do
      post :signin_post, :do_signup => true, :identity_email => { :email => 'bar.foo@sample.com', :password => 'barfoo', :commercial => 1 }
    end
    assert_response :redirect
    assert_redirected_to root_path
    assert !assigns(:identity).new_record?
    assert assigns(:identity).email == 'bar.foo@sample.com'
    assert assigns(:identity).commercial?
    assert_equal :signup, assigns(:mode)
    assert_equal I18n.t("identity.form.success.signup", :name => assigns(:identity).name), flash[:success]
  end
  
  def test_signin_post_mode_signin_fails
    xhr :post, :signin_post, :do_signin => true, :identity_email => { :email => 'unknown@sample.com', :password => '' }
    assert_response :success
    assert assigns(:identity).new_record?
    assert_equal :signin, assigns(:mode)
    assert_equal "sessions/forms/signin", assigns(:partial)
    assert_equal "text/javascript", @response.content_type
    assert_equal I18n.t("identity.form.error.signin"), assigns(:error)
  end
    
  def test_signin_post_mode_reset_fails
    xhr :post, :signin_post, :do_reset => true, :identity_email => { :email => 'unknown@sample.com' }
    assert_response :success
    assert assigns(:identity).new_record?
    assert_equal :reset, assigns(:mode)
    assert_equal "sessions/forms/signin", assigns(:partial)
    assert_equal "text/javascript", @response.content_type
    assert_equal I18n.t("identity.form.error.reset"), assigns(:error)
  end

  def test_signin_post_mode_signup_fails
    xhr :post, :signin_post, :do_signup => true, :identity_email => { :email => 'unknown@sample.com', :password => '' }
    assert_response :success
    assert assigns(:identity).new_record?
    assert_equal :signup, assigns(:mode)
    assert_equal "sessions/forms/email", assigns(:partial)
    assert_equal "text/javascript", @response.content_type
    assert_equal I18n.t("identity.form.error.signup"), assigns(:error)
  end
  
  def test_destroy
    @controller.expects(:signout).once
    delete :destroy
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.destroy"), flash[:notice]
  end
  
  def test_cancel
    post :cancel
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.cancel"), flash[:warn]
  end

  def test_set_partials
    signins = {
      "confirm"   => { "confirmed"  => %w(confirm) },
      "email"     => { "confirmed"  => %w(signin email) },
      "twitter"   => { "twitter"    => %w(twitter) },
      "facebook"  => { "facebook"   => %w(facebook) },
      "email"     => { "email"      => %w(signin email) },
      "address"   => { "address"    => %w(address) },
      "foobar"    => { nil          => %w(signin twitter facebook email) }
    }
    signins.each do |test, request|
      if request.keys.first == "confirmed"
        if test == "confirm" then @controller.stubs(:identity?).once.with(:email).returns(true)
        else                      @controller.stubs(:identity?).once.with(:email).returns(false)
        end
      end
      
      @controller.params = { :req => request.keys.first }
      @controller.send(:set_partials)
      
      assert assigns(:partials)
      assert_equal request.values.first, assigns(:partials)
    end
  end
  
end