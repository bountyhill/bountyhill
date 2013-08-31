# encoding: UTF-8

require_relative "../test_helper.rb"

class RunsControllerTest < ActionController::TestCase

  def setup
    @controller = RunsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    
    @owner = Factory(:user)
    @owner.identities << Factory(:twitter_identity)
    @quest = Factory(:quest, :owner => @owner, :bounty => Money.new(12000, "EUR"))

    login @owner
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
pend "TODO: enable user 'draft' in test mode as well!" do
    logout
    @draft = Factory(:quest, :owner => User.draft, :bounty => Money.new(12000, "EUR"))
    
      assert_no_difference "Quest.count" do
      get :show, :id => @draft.id
    end
    assert_response :redirect
    assert_redirected_to signin_path(:req => :any)
    assert_equal @draft, assigns(:quest)
end
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
    # TODO: @quest.expects(:cancel!).with({ 'foo' => 'bar' })
    Quest.any_instance.expects(:cancel!).with({ 'foo' => 'bar' })
    
    assert_no_difference "Quest.count" do
      post :destroy, :id => @quest.id, :quest => { 'foo' => 'bar' }
    end
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @quest, assigns(:quest)
    assert_equal I18n.t("quest.action.cancelled", :quest => @quest.title), flash[:success]
  end

end