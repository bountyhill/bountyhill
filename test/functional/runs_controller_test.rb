# encoding: UTF-8

require_relative "../test_helper.rb"

class RunsControllerTest < ActionController::TestCase

  def setup
    @controller = RunsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    
    @owner = Factory(:twitter_identity).user
    @quest = Factory(:quest, :owner => @owner, :bounty => Money.new(12000, "EUR"))

    login @owner
  end

  def test_show_requires_identity_login
    User.any_instance.expects(:identities).at_least(Identity.oauth_identities.size).returns([])

    assert_no_difference "Quest.count" do
      get :show, :id => @quest.id
    end
    
    assert_response :redirect
    assert_redirected_to signin_path(:req => :login)
    assert_equal @quest, assigns(:quest)
  end
  
  def test_show_requires_identity_address_for_commercial_users
    User.any_instance.expects(:commercial?).returns(true)

    assert_no_difference "Quest.count" do
      get :show, :id => @quest.id
    end
    assert_response :redirect
    assert_redirected_to signin_path(:req => :address)
    assert_equal @quest, assigns(:quest)
  end

  def test_show
    User.expects(:transfer!).once
    assert_no_difference "Quest.count" do
      get :show, :id => @quest.id
    end
    assert_response :success
    assert_template "shares/new", :layout => "dialog"
    assert_equal @quest, assigns(:quest)
    assert assigns(:share).present?
  end
  
  def test_show_draft
    logout
    draft = Factory(:quest, :owner => User.draft)
    assert_no_difference "Quest.count" do
      get :show, :id => draft.id
    end
    assert_response :redirect
    assert_redirected_to signin_path(:req => :login)
    assert_equal draft, assigns(:quest)
  end
  
  def test_cancel
    assert_no_difference "Quest.count" do
      get :cancel, :id => @quest.id
    end
    assert_response :success
    assert_template :cancel
    assert_equal @quest, assigns(:quest)
  end
  
  def test_destroy
    # TODO: @quest.expects(:stop!).with({ 'foo' => 'bar' })
    Quest.any_instance.expects(:stop!).with({ 'foo' => 'bar' })
    
    assert_no_difference "Quest.count" do
      post :destroy, :id => @quest.id, :quest => { 'foo' => 'bar' }
    end
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @quest, assigns(:quest)
    assert_equal I18n.t("quest.action.stopped", :quest => @quest.title), flash[:success]
  end

end