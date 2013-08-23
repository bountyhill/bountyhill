# encoding: UTF-8

require_relative "../test_helper.rb"

class QuestsControllerTest < ActionController::TestCase

  def setup
    @controller = QuestsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super

    # init common test objects
    @searcher = Factory(:user)
    @quest    = Factory(:quest, :owner => @searcher, :bounty => Money.new(12000, "EUR"))
    
    login @searcher
  end
  
  # all quests visible by current user
  def test_index
    # current user sees only active quests
    get :index
    assert_response :success
    assert_template :index
    assert_equal [], assigns(:quests)

    @quest.start!
    get :index
    assert_response :success
    assert_template :index
    assert_equal [@quest], assigns(:quests)
  end
  
  def test_index_with_given_owner
    # current user sees own quests
    get :index, :owner_id => @searcher.id
    assert_response :success
    assert_template :index
    assert_equal [@quest], assigns(:quests)
  end
  
  def test_index_with_given_location
    @quest.create_location(:address => "Berlin, Germany")
    @request.stubs(:location).returns(OpenStruct.new(:name => "Potsdam, Germany"))
    
    # radius is too short
    get :index, :owner_id => @searcher.id, :radius => 10
    assert_response :success
    assert_template :index
    assert_equal [], assigns(:quests)
    
    # radius just fits
    get :index, :owner_id => @searcher.id, :radius => 50
    assert_response :success
    assert_template :index
    assert_equal [@quest], assigns(:quests)
  end
  
  def test_index_with_given_category
    Quest::CATEGORIES.each_with_index do |category, index|
      # ensure quests category does not match current category
      @quest.update_attribute(:category, Quest::CATEGORIES[index-1])
      assert @quest.category != category
      
      # test no quests available for given category
      get :index, :owner_id => @searcher.id, :category => category
      assert_response :success
      assert_template :index
      assert_equal [], assigns(:quests)
      

      # ensure quests category does match current category
      @quest.update_attribute(:category, Quest::CATEGORIES[index])
      assert @quest.category == category
      
      # test quests available for given category
      get :index, :owner_id => @searcher.id, :category => category
      assert_response :success
      assert_template :index
      assert_equal [@quest], assigns(:quests)
    end
  end
  
  def test_show
    # show quest to owner
    get :show, :id => @quest.id
    assert_response :success
    assert_template :show
    assert_equal @quest, assigns(:quest)
  end

  def test_show_public
    # show quest unknown user
    logout
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => @quest.id
    end
    
    @quest.start!
    get :show, :id => @quest.id
    assert_response :success
    assert_template :show
    assert_equal @quest, assigns(:quest)
  end
  
  def test_show_preview
    # show quest to owner in preview mode
    get :show, :id => @quest.id, :preview => true
    assert_response :success
    assert_template :preview
    assert_equal @quest, assigns(:quest)
  end
  
  def test_show_draft
    # fake quest belongs to user draft
    User.any_instance.stubs(:draft?).returns(true)
    
    # show draft to unregistred user
    logout
    get :show, :id => @quest.id
    assert_response :success
    assert_template :show
    assert_equal @quest, assigns(:quest)
  end
  
  def test_new
    @request.stubs(:location).returns(OpenStruct.new(:name => "Berlin, Germany"))

    assert_no_difference "Quest.count" do
      get :new
    end
    assert_response :success
    assert_template :new
    assert_equal Quest::DEFAULT_BOUNTY, assigns(:quest).bounty_in_cents
    assert_equal @request.location.name, assigns(:quest).location.address
  end

  def test_edit
    assert_no_difference "Quest.count" do
      get :edit, :id => @quest.id
    end
    assert_response :success
    assert_template :new
    assert assigns(:quest).location.present?
  end
  
  def test_create
    # quest is invalid
    assert_no_difference "Quest.count" do
      post :create, :quest => { :title => "foo bar" }
    end
    assert_response :success
    assert_template :new
    assert assigns(:quest).new_record?
    assert !assigns(:quest).valid?
    assert assigns(:quest).location.nil?

    # quest is valid
    assert_difference "Quest.count", +1 do
      post :create, :quest => valid_quest_params
    end
    assert_response :redirect
    assert_redirected_to quest_path(assigns(:quest), :preview => true)
    assert_equal "Berlin, Germany", assigns(:quest).location.address
  end
  
  def test_create_as_draft_user
    logout

    pend "TODO: enable user 'draft' in test mode as well!" do
      assert_difference "Quest.count", +1 do
        post :create, :quest => valid_quest_params
      end
      assert_response :redirect
      assert_redirected_to quest_path(assigns(:quest), :preview => true)
      assert_equal User.draft, assigns(:quest).owner
    end
  end
  
  def test_update
    # quest is invalid
    put :update, :id => @quest.id, :quest => { :title => "" }
    assert_response :success
    assert_template :new
    assert_equal @quest, assigns(:quest)

    # quest is valid
    put :update, :id => @quest.id, :quest => valid_quest_params.merge(:title => "bar foo")
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @quest.reload, assigns(:quest)
    assert_equal "bar foo", assigns(:quest).title
  end
  
  def test_update_location
    put :update, :id => @quest.id, :quest => { :restrict_location => true, :location_attributes => { :address => "Berlin, Germany" }}
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @quest.reload, assigns(:quest)
    assert_equal "Berlin, Germany", assigns(:quest).location.address

    put :update, :id => @quest.id, :quest => { :restrict_location => true, :location_attributes => { :address => "Potsdam, Germany" }}
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @quest.reload, assigns(:quest)
    assert_equal "Potsdam, Germany", assigns(:quest).location.address

    put :update, :id => @quest.id, :quest => { :restrict_location => "" }
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert_equal @quest.reload, assigns(:quest)
    assert @quest.location.nil?
  end

  def test_destroy
    assert_difference "Quest.count", -1 do
      delete :destroy, :id => @quest.id
    end
    assert_response :redirect
    assert_redirected_to quests_url
  end
  
  
private
  
  def valid_quest_params
    {
      :title => "foo bar",
      :description => lorem_ipsum,
      :category => "misc",
      :bounty => 100,
      :restrict_location => true,
      :location_attributes => { :address => "Berlin, Germany" }
    }
  end

end