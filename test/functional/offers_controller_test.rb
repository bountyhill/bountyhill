# encoding: UTF-8

require_relative "../test_helper.rb"

class OffersControllerTest < ActionController::TestCase

  def setup
    @controller = OffersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super

    # init common test objects
    @offerer  = Factory(:user)
    @quest    = Factory(:quest, :owner => admin, :bounty => Money.new(12000, "EUR")).start!
    @offer    = Factory(:offer, :quest => @quest, :owner => @offerer)
    
    login @offerer
  end
  
  # all offers visible by current user
  def test_index
    # common user sees no offers
    get :index
    assert_response :success
    assert_template :index
    assert_equal [], assigns(:offers)
    
    # admin user sees all offers
    login admin
    get :index
    assert_response :success
    assert_template :index
    assert_equal [@offer], assigns(:offers)
  end

  # all offers of particular quest
  def test_index_with_given_quest
    login @quest.owner
    get :index, :quest_id => @quest.id
    assert_response :success
    assert_template :index
    assert_equal [@offer], assigns(:offers)
  end

  # all offers of particular owner
  def test_index_with_given_owner
    get :index, :owner_id => @offerer.id
    assert_response :success
    assert_template :index
    assert_equal [@offer], assigns(:offers)
  end

  # all offers of particular state
  def test_index_with_given_state
    Offer::STATES.each_with_index do |state, index|
      # test no offers available for given state
      @offer.update_attribute(:state, Offer::STATES[index-1])
      assert @offer.state != state
      get :index, :owner_id => @offerer.id, :state => state
      assert_response :success
      assert_template :index
      assert_equal [], assigns(:offers)
      
      # test offers available for given state
      @offer.update_attribute(:state, state)
      get :index, :owner_id => @offerer.id, :state => state
      assert_response :success
      assert_template :index
      assert_equal [@offer], assigns(:offers)
    end
  end

  def test_show
    # show to owner
    get :show, :id => @offer.id
    assert_response :success
    assert_template :show
    assert_equal @offer, assigns(:offer)
    assert assigns(:offer).viewed_at.nil?

    # show to quest owner
    login @quest.owner
    get :show, :id => @offer.id
    assert_response :success
    assert_template :show
    assert_equal @offer, assigns(:offer)
    assert assigns(:offer).viewed_at.present?
  end
  
  def test_new
    # user is redirected if 'confirmed' email identity is not given
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :redirect
    assert_redirected_to signin_path(:req => :confirmed)
    
    # assume user has 'confirmed' email identity
    @offerer.identity(:email).confirm!(true)
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :success
    assert_template :new
    assert assigns(:offer).new_record?
    assert_equal @quest, assigns(:offer).quest
    
    # test given with location
    @request.stubs(:location).returns(OpenStruct.new(:name => "Berlin, Germany"))
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :success
    assert_template :new
    assert assigns(:offer).new_record?
    assert_equal @request.location.name, assigns(:offer).location
  end
  
  def test_edit
    assert_no_difference "Offer.count" do
      get :edit, :id => @offer.id
    end
    assert_response :success
    assert_template :new
    assert_equal @offer, assigns(:offer)
  end
  
  def test_create
    # offer is invalid
    assert_no_difference "Offer.count" do
      post :create, :offer => { :quest_id => @quest.id }
    end
    assert_response :success
    assert_template :new
    assert assigns(:offer).new_record?
    assert !assigns(:offer).valid?

    # offer is valid
    assert_difference "Offer.count", +1 do
      post :create, :offer => { :quest_id => @quest.id, :title => "foo bar", :description => lorem_ipsum }
    end
    assert_response :redirect
    assert_redirected_to offer_path(assigns(:offer), :preview => true)
    assert !assigns(:offer).new_record?
  end
  
  def test_update
    # offer is invalid
    put :update, :id => @offer.id, :offer => { :title => "" }
    assert_response :success
    assert_template :new
    assert_equal @offer, assigns(:offer)

    # offer is valid
    put :update, :id => @offer.id, :offer => { :title => "foo bar" }
    assert_response :redirect
    assert_redirected_to offer_path(@offer)
    assert_equal @offer.reload, assigns(:offer)
  end
  
  def test_destroy
    assert_difference "Offer.count", -1 do
      delete :destroy, :id => @offer.id
    end
    assert_response :redirect
    assert_redirected_to offers_url(:owner => @offerer)
  end
  
  def test_activate
    # get activation form
    get :activate, :id => @offer.id
    assert_response :success
    assert_template :activate
    assert_equal @offer, assigns(:offer)
    
    # post activation
    Offer.any_instance.expects(:activate!).once   # TODO: @offer.reload.expects(:activate!).once
    post :activate, :id => @offer.id
    assert_response :redirect
    assert_redirected_to offer_path(@offer)
    assert_equal @offer, assigns(:offer)
  end
  
  def test_withdraw
    # get withdraw form
    get :withdraw, :id => @offer.id
    assert_response :success
    assert_template :withdraw
    assert_equal @offer, assigns(:offer)

    # post withdrawel
    Offer.any_instance.expects(:withdraw!).once   # TODO: @offer.expects(:withdraw!).once
    post :withdraw, :id => @offer.id
    assert_response :redirect
    assert_redirected_to quest_path(@offer.quest)
    assert_equal @offer, assigns(:offer)
  end
  
  def test_accept
    # get accept form
    get :accept, :id => @offer.id
    assert_response :success
    assert_template :accept
    assert_equal @offer, assigns(:offer)

    # post acception
    Offer.any_instance.expects(:accept!).once   # TODO: @offer.expects(:accept!).once
    post :accept, :id => @offer.id
    assert_response :redirect
    assert_redirected_to quest_path(@offer.quest)
    assert_equal @offer, assigns(:offer)
  end
  
  def test_reject
    # get reject form
    get :reject, :id => @offer.id
    assert_response :success
    assert_template :reject
    assert_equal @offer, assigns(:offer)

    # post rejection
    Offer.any_instance.expects(:reject!).once   # TODO: @offer.expects(:reject!).once
    post :reject, :id => @offer.id
    assert_response :redirect
    assert_redirected_to quest_path(@offer.quest)
    assert_equal @offer, assigns(:offer)
  end
  
end