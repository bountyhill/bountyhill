# encoding: UTF-8

require_relative "../test_helper.rb"

class SharesControllerTest < ActionController::TestCase

  def setup
    @controller = SharesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    
    @owner = Factory(:user)
    @quest = Factory(:quest, :owner => @owner, :bounty => Money.new(12000, "EUR"))
    # TODO: @share = Factory(:share, :quest => @quest, :owner => @owner, :identities => { 'twitter' => true })
    @share = Share.create(:message => "message", :quest => @quest, :owner => @owner, :identities => { 'twitter' => true })
    
    login @owner
  end
  
  def test_new
    assert_no_difference "Share.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :success
    assert_template :new, :layout => 'dialog'
    assert_equal @quest, assigns(:share).quest
    assert_equal @owner, assigns(:share).owner
    assert !assigns(:share).identities.values.all?
  end
  
  def test_create
    assert_difference "Share.count" do
      post :create, :share => { 
        :quest_id   => @quest.id,
        :message    => "Foo Bar",
        :identities => { :twitter => true }
      }
    end
    assert_response :redirect
    assert_redirected_to share_path(Share.last)
    assert_equal @quest, assigns(:share).quest
    assert_equal @owner, assigns(:share).owner
    assert assigns(:share).identities['twitter']
  end

  def test_create_fails
    assert_no_difference "Share.count" do
      post :create, :share => { :quest_id => @quest.id }
    end
    assert_response :success
    assert_template :new, :layout => 'dialog'
    assert_equal @quest, assigns(:share).quest
    assert_equal @owner, assigns(:share).owner
  end
  
  #
  # user has identity for requested network (quest already started)
  def test_show
    @owner.identities << Factory(:twitter_identity)
    # TODO: @quest.expects(:active?).once.returns(true)
    Quest.any_instance.expects(:active?).once.returns(true)
    # TODO: @share.expects(:post).with(:twitter).once
    Share.any_instance.expects(:post).with(:twitter).once
    
    assert_no_difference "Share.count" do
      get :show, :id => @share.id
    end
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @share, assigns(:share)
    assert_equal @quest, assigns(:quest)
  end
  
  #
  # user has identity for requested network (quest not started yet)
  def test_show_starts_quest
    @owner.identities << Factory(:twitter_identity)
    # TODO: @quest.expects(:active?).once.returns(false)
    Quest.any_instance.expects(:active?).once.returns(false)
    # TODO @quest.expects(:start!).once
    Quest.any_instance.expects(:start!).once
    # TODO: @share.expects(:post).with(:twitter).once
    Share.any_instance.expects(:post).with(:twitter).once
    
    assert_no_difference "Share.count" do
      get :show, :id => @share.id
    end
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @share, assigns(:share)
    assert_equal @quest, assigns(:quest)
  end

  #
  # requested network requires user's identity to be provided
  def test_show_requires_identity
    assert_no_difference "Share.count" do
      get :show, :id => @share.id
    end
    assert_response :redirect
    assert_redirected_to signin_path(:req => 'twitter')
    assert_equal @share, assigns(:share)
    assert_equal @quest, assigns(:quest)
  end 
end