# encoding: UTF-8

require_relative "../test_helper.rb"

class IdentitiesControllerTest < ActionController::TestCase

  def setup
    @controller = IdentitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super

    @email_identity = Factory(:email_identity)
    @user = @email_identity.user
    login @user
  end

  # --- test restful identities actions ---------------------------------------------
  
  def test_new
    %w(email address twitter facebook google linkedin xing).each do |provider|
      get :new, :provider => provider
      assert_response :success
      assert_template 'new'
      assert assigns(:identity).new_record?
      assert assigns(:identity).kind_of?(Identity.provider(provider.to_sym))
    end
  end

  def test_create
    assert_no_difference "User.count" do
      assert_difference "Identity::Address.count" do
        post :create, :identity_address => { 
          :commercial => true,
          :company => "bountyhill UG (haftungsbeschränkt) & Co. KG",
          :address1 => "Berliner Straße 12",
          :city => "Berlin",
          :zipcode => '13187',
          :country => "Germany",
          :phone => '491636867766' }
      end
    end
    assert_response :redirect
    assert_redirected_to user_path(@email_identity.user)
    assert assigns(:identity).kind_of?(Identity::Address)
    assert assigns(:identity).commercial
  end
  
  def test_create_with_email_already_present_on_other_identity
    logout
    identity_facebook  = Factory(:facebook_identity, :info => { :nickname => "inyourfacebook", :email => "foo@bar.com" })
    
    assert_no_difference "User.count" do
      assert_difference "Identity::Email.count" do
        post :create, :identity_email => { 
          :email => identity_facebook.email,
          :password => "foobar",
          :password_confirmation => "foobar",
          :commercial => true }
      end
    end
    assert_response :redirect
    assert_redirected_to user_path(identity_facebook.user)
    assert assigns(:identity).kind_of?(Identity::Email)
    assert assigns(:identity).commercial
  end

  def test_create_fails
    assert_no_difference "Identity::Address.count" do
      xhr :post, :create, :identity_address => { :commercial => true }
    end
    assert_response :success
    assert_template 'create'
    assert_equal 'text/javascript', @response.content_type
    assert assigns(:identity).kind_of?(Identity::Address)
  end
  
  def test_edit
    @address_identity   = Factory(:address_identity,  :user => @user)
    @twitter_identity   = Factory(:twitter_identity,  :user => @user)
    @facebook_identity  = Factory(:facebook_identity, :user => @user)
    @google_identity    = Factory(:google_identity,   :user => @user)
    
    [@email_identity, @address_identity, @twitter_identity, @facebook_identity, @google_identity].each do |identity|
      get :edit, :id => identity.id
      assert_response :success
      assert_template 'edit'
      assert_equal identity, assigns(:identity)
    end
  end
  
  def test_update
    @address_identity = Factory(:address_identity, :user => @user)
    
    put :update, :id => @address_identity.id, :identity_address => { :company => "Foo Bar" }
    assert_response :redirect
    assert_redirected_to user_path(@address_identity.user)
    assert_equal "Foo Bar", @address_identity.reload.company
  end

  def test_update_fails
    @address_identity = Factory(:address_identity, :user => @user)
    
    xhr :put, :update, :id => @address_identity.id, :identity_address => { :address1 => "" }
    assert_response :success
    assert_template 'update'
    assert_equal 'text/javascript', @response.content_type
    assert assigns(:identity).kind_of?(Identity::Address)
    assert assigns(:identity).errors.present?
  end
  
  def test_delete
    @address_identity   = Factory(:address_identity,  :user => @user)
    @twitter_identity   = Factory(:twitter_identity,  :user => @user)
    @facebook_identity  = Factory(:facebook_identity, :user => @user)
    @google_identity    = Factory(:google_identity,   :user => @user)
    
    [@email_identity, @address_identity, @twitter_identity, @facebook_identity, @google_identity].each do |identity|
      get :delete, :id => identity.id
      assert_response :success
      assert_template 'delete'
      assert_equal identity, assigns(:identity)
    end
  end

  def test_destroy
    @address_identity   = Factory(:address_identity,  :user => @user)
    @twitter_identity   = Factory(:twitter_identity,  :user => @user)
    @facebook_identity  = Factory(:facebook_identity, :user => @user)
    @google_identity    = Factory(:google_identity,   :user => @user)

    [@address_identity, @twitter_identity, @facebook_identity, @google_identity].each do |identity|
      assert_difference("#{identity.class.name}.count", -1) do
        delete :destroy, :id => identity.id
        assert_response :redirect
        assert_redirected_to user_path(@user)
        assert_equal @user, assigns(:user)
        assert !@user.reload.identity(identity.provider)
      end
    end
  end

  def test_destroy_fails
    # single identity cannot be destroyed
    assert_raises RuntimeError do
      assert_no_difference("Identity::Email.count") do
        delete :destroy, :id => @email_identity.id
      end
    end
    
    # last identity of user cannot be destroyed
    identity = Factory(:twitter_identity, :user => @user)
    @email_identity.destroy
    assert_raises RuntimeError do
      assert_no_difference("Identity::Twitter.count") do
        delete :destroy, :id => identity.id
      end
    end
  end
  

  # --- test Omniauth social identities actions ---------------------------------------------

  def test_init
    logout
    
    post :init, :provider => 'twitter', :identity_twitter => { :follow_bountyhermes => true, :commercial => true }
    assert_response :redirect
    assert_redirected_to "/auth/twitter"
    assert @request.session[:identity_params].present?
    assert @request.session[:identity_params][:follow_bountyhermes]
    assert @request.session[:identity_params][:commercial]
  end
  
  def test_success_fails
    logout
    
    # fails since no uuid is given
    post :success, :provider => :twitter
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.failure"), flash[:error]
  end
  
  def test_success
    setup_successful_twitter_authentification(:follow_bountyhermes => true)
    
    post :success, :provider => :twitter
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal Identity::Twitter.last, assigns(:identity)
    assert_false assigns(:identity).commercial?
    assert_nil assigns(:identity).email
    assert_equal I18n.t("sessions.auth.success"), flash[:success]
  end
  
  def test_success_for_commercial_user
    setup_successful_twitter_authentification(:commercial => true)
    
    post :success, :provider => :twitter
    assert assigns(:identity).commercial?
  end
  
  def test_success_with_given_email
    setup_successful_twitter_authentification(:email => "foo@bar.com")
    
    post :success, :provider => :twitter
    assert_equal "foo@bar.com", assigns(:identity).email
  end

  def test_failure
    logout
    
    get :failure
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal I18n.t("sessions.auth.failure"), flash[:error]
  end

  # --- test update email ---------------------------------------------
    
  def test_update_email
    assert_not_equal "barfoo", @user.identity(:email).password

    put :update, :id => @email_identity.id, :identity_email => {
      :password_new => "barfoo",
      :password_new_confirmation  => "barfoo",
      :password => @email_identity.password
    }
    assert_response :redirect
    assert_redirected_to user_path(@user)
    assert assigns(:identity).valid?
    assert_equal "barfoo", assigns(:identity).password
    assert_equal I18n.t("notice.update.success", :record => Identity::Email.human_attribute_name(:password)), flash[:success]
  end

  def test_update_email_fails
   # wrong password
   xhr :put, :update, :id => @email_identity.id, :identity_email => { :password => "foo bar" }
    assert_response :success
    assert_template "update"
    assert_equal @email_identity, assigns(:identity)
    assert assigns(:identity).errors[:password]
    assert_equal :email , assigns(:provider)
    assert_equal "text/javascript", @response.content_type

    # password_new and password_new_confirmation are unequal
    xhr :put, :update, :id => @email_identity.id, :identity_email => {
      :password_new => "barfoo",
      :password_new_confirmation  => "foobar",
      :password => @email_identity.password
    }
    assert_response :success
    assert_template "update"
    assert_equal @email_identity, assigns(:identity)
    assert assigns(:identity).errors[:password]
    assert_equal :email , assigns(:provider)
    assert_equal "text/javascript", @response.content_type
  end
  
  protected
  
  def setup_successful_twitter_authentification(identity_params = {})
    logout

    OmniAuth.config.add_mock(:twitter, {:provider => 'twitter'})
    
    @request.env["omniauth.auth"]       = OmniAuth.config.mock_auth[:twitter]
    @request.session[:identity_params]  = identity_params

    identity_twitter = Factory(:twitter_identity, :identifier => '12345')
    Identity::Twitter.expects(:find_or_create).once.returns(identity_twitter)
    
    if(identity_params[:follow_bountyhermes])
      identity_twitter.expects(:follow).once.returns(true)
      identity_twitter.expects(:direct_message).with(I18n.t("tweet.follow.success")).once
    else
      identity_twitter.expects(:follow).never
      identity_twitter.expects(:direct_message).never
    end
  end

end