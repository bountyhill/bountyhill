# encoding: UTF-8

require_relative "../test_helper.rb"

class SessionsControllerTest < ActionController::TestCase

  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  def test_signin_get
    # request signin
    get :signin_get
    assert_response :success
    assert_template 'new', :layout => 'dialog'
    assert assigns(:identity).kind_of?(Identity::Email)
    assert assigns(:identity).newsletter_subscription
    assert_equal :signin, assigns(:mode)

    # request signup
    get :signin_get, :req => :signup
    assert_response :success
    assert_template 'new', :layout => 'dialog'
    assert assigns(:identity).kind_of?(Identity::Email)
    assert assigns(:identity).newsletter_subscription
    assert_equal :signup, assigns(:mode)
    assert_equal :signup, @request.session[ApplicationController::RequiredIdentity::SESSION_KEY][:kind]
    assert_nil @request.session[ApplicationController::RequiredIdentity::SESSION_KEY][:on_success]
    assert_nil @request.session[ApplicationController::RequiredIdentity::SESSION_KEY][:on_cancel]
  end

  def test_signin_post
    identity = Factory(:identity)

    # request signin
    post :signin_post, :do_signin => true, :identity => { :email => identity.email, :password => identity.password }
    assert_response :redirect
    assert_redirected_to root_path
    assert assigns(:identity).id
    assert_equal :signin, assigns(:mode)
    assert_equal I18n.t("identity.form.success.signin", :name => assigns(:identity).name), flash[:success]
    
    # request reset
    UserMailer.expects(:reset_password).once.with(identity.user).returns("foobar")
    Deferred.expects(:mail).once.with("foobar")
    
    post :signin_post, :do_reset => true, :identity => { :email => identity.email }
    assert_response :redirect
    assert_redirected_to root_path
    assert assigns(:identity).id
    assert_equal :reset, assigns(:mode)
    assert_equal I18n.t("identity.form.success.reset", :name => assigns(:identity).name), flash[:success]

    # request signup
    Identity::Email.expects(:create).once.returns(identity)
    
    post :signin_post, :do_signup => true, :identity => { :email => 'bar.foo@sample.com', :password => 'barfoo' }
    assert_response :redirect
    assert_redirected_to root_path
    assert assigns(:identity).id
    assert_equal :signup, assigns(:mode)
    assert_equal I18n.t("identity.form.success.signup", :name => assigns(:identity).name), flash[:success]
    
    #request unknown mode
    assert_raise(ArgumentError) { post :signin_post }
  end
  
  def test_signin_post_fails
    # request signin
    xhr :post, :signin_post, :do_signin => true, :identity => { :email => 'unknown@sample.com', :password => '' }
    assert_response :success
    assert assigns(:identity).id.nil?
    assert_equal :signin, assigns(:mode)
    assert_equal "sessions/forms/email", assigns(:partial)
    assert_equal I18n.t("identity.form.error.signin"), assigns(:error)
    
    # request reset
    xhr :post, :signin_post, :do_reset => true, :identity => { :email => 'unknown@sample.com' }
    assert_response :success
    assert assigns(:identity).id.nil?
    assert_equal :reset, assigns(:mode)
    assert_equal "sessions/forms/email", assigns(:partial)
    assert_equal I18n.t("identity.form.error.reset"), assigns(:error)
    
    # request signup
    xhr :post, :signin_post, :do_signup => true, :identity => { :email => 'unknown@sample.com', :password => '' }
    assert_response :success
    assert assigns(:identity).id.nil?
    assert_equal :signup, assigns(:mode)
    assert_equal "sessions/forms/register", assigns(:partial)
    assert_equal I18n.t("identity.form.error.signup"), assigns(:error)
  end
  
  def test_destroy
    @controller.expects(:signout).once
    delete :destroy
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.destroy"), flash[:notice]
  end
  
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
    identity_twitter.expects(:direct_message).with(I18n.t("notice.tweet.thanks_for_following")).once
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

  def test_cancel
    post :cancel
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.cancel"), flash[:notice]
  end

  def test_set_partials
    signins = {
      "confirm"   => { "confirmed"  => %w(confirm) },
      "email"     => { "confirmed"  => %w(email register) },
      "twitter"   => { "twitter"    => %w(twitter) },
      "facebook"  => { "facebook"   => %w(facebook) },
      "email"     => { "email"      => %w(email register) },
      "foobar"    => { nil          => %w(email twitter facebook register) }
    }
    signins.each do |test, request|
      if request.keys.first == "confirmed"
        if test == "confirm" then  @controller.stubs(:identity?).once.with(:email).returns(true)
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