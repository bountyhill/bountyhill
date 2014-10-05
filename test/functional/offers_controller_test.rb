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
    @searcher = Factory(:twitter_identity).user
    @other    = Factory(:facebook_identity).user

    @quest    = Factory(:quest, :owner => @searcher, :bounty => Money.new(12000, "EUR")).start!
    @offer    = Factory(:offer, :quest => @quest, :owner => @offerer)
    
    login @offerer
  end
  
  # no offers are displayed if no owner id is given
  def test_index
    # xhr request
    xhr :get, :index
    assert_response :success
    assert_template :index
    assert_equal 'text/javascript', @response.content_type
    assert_equal [], assigns(:offers)

    # offerer did not receive any offers
    get :index
    assert_response :success
    assert_template :index
    assert_equal 'text/html', @response.content_type
    assert_equal [], assigns(:offers)
    
    # other user did not receive any offers
    login @other
    get :index
    assert_response :success
    assert_template :index
    assert_equal [], assigns(:offers)
    
    # searcher did receive offer, but it's just prepared (new)
    assert @offer.new?
    login @searcher
    get :index
    assert_response :success
    assert_template :index
    assert_equal [], assigns(:offers)

    # searcher did receive offer and it's not new
    @offer.update_attribute(:state, 'active')
    assert !@offer.new?
    login @searcher
    get :index
    assert_response :success
    assert_template :index
    assert_equal [@offer], assigns(:offers)
  end

  # all offers of particular quest
  def test_index_with_given_quest
    login @quest.owner
    # no offer with status != 'new'
    get :index, :quest_id => @quest.id
    assert_response :success
    assert_template :index
    assert_equal [], assigns(:offers)

    # one active offer
    @offer.update_attribute(:state, 'active')
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

    # test show to other
    login @other
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => @offer.id
    end

    # quest's owner does not see prepared (=new) offer
    login @quest.owner
    assert_raises ActiveRecord::RecordNotFound do
      get :show, :id => @offer.id
    end
    
    # quest's owner does see active offer
    @offer.update_attribute(:state, 'active')
    get :show, :id => @offer.id
    assert_response :success
    assert_template :show
    assert_equal @offer, assigns(:offer)
    assert assigns(:offer).viewed_at.present?
  end
  
  def test_new
    # user is redirected if email identity is not confirmed yet
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :redirect
    assert_redirected_to signin_path(:req => :confirmed)
    
    # assume user has 'confirmed' email identity
    @offerer.identity(:email).confirm!(true)

    # test new succeeds
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :success
    assert_template :new
    assert assigns(:offer).new_record?
    assert_equal @quest, assigns(:offer).quest
    
    # test new with location succeeds
    @request.stubs(:location).returns(OpenStruct.new(:name => "Berlin, Germany"))
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :success
    assert_template :new
    assert assigns(:offer).new_record?
    assert_equal @request.location.name, assigns(:offer).location

    # user is redirected if address identity is not given for commercial user
    User.any_instance.expects(:commercial?).returns(true)
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :redirect
    assert_redirected_to signin_path(:req => :address)
    
    # user is redirected if he owns quest to offer on
    User.any_instance.expects(:commercial?).returns(false)
    User.any_instance.expects(:owns?).with(@quest).returns(true)
    assert_no_difference "Offer.count" do
      get :new, :quest_id => @quest.id
    end
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
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
    assert_equal I18n.t("notice.submit.success", :record => Offer.model_name.human), flash[:success]
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
    assert_equal I18n.t("notice.update.success", :record => Offer.model_name.human), flash[:success]
  end
  
  def test_destroy
    assert_difference "Offer.count", -1 do
      delete :destroy, :id => @offer.id
    end
    assert_response :redirect
    assert_redirected_to offers_url(:owner => @offerer)
    assert_equal I18n.t("notice.destroy.success", :record => Offer.model_name.human), flash[:success]
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
    assert_equal I18n.t("offer.action.activate", :offer => @offer.title), flash[:success]
  end
  
  def test_withdraw
    # get withdraw form
    get :withdraw, :id => @offer.id
    assert_response :success
    assert_template :withdraw
    assert_equal @offer, assigns(:offer)

    # post withdrawel
    Offer.any_instance.expects(:withdraw!).once.with('withdrawal' => 'other_reason')   # TODO: @offer.expects(:withdraw!).once
    post :withdraw, :id => @offer.id, :offer => { :withdrawal => 'other_reason' }
    assert_response :redirect
    assert_redirected_to offer_path(@offer)
    assert_equal @offer, assigns(:offer)
    assert_equal I18n.t("offer.action.withdraw", :offer => @offer.title), flash[:success]
  end
  
  def test_accept
    # get accept form
    get :accept, :id => @offer.id
    assert_response :success
    assert_template :accept
    assert_equal @offer, assigns(:offer)

    # post acception
    Offer.any_instance.expects(:accept!).once.with('acceptance' => 'other_reason')   # TODO: @offer.expects(:accept!).once
    post :accept, :id => @offer.id, :offer => { :acceptance => 'other_reason' }
    assert_response :redirect
    assert_redirected_to offer_path(@offer)
    assert_equal @offer, assigns(:offer)
    assert_equal I18n.t("offer.action.accept", :offer => @offer.title), flash[:success]
  end
  
  def test_reject
    # get reject form
    get :reject, :id => @offer.id
    assert_response :success
    assert_template :reject
    assert_equal @offer, assigns(:offer)

    # post rejection
    Offer.any_instance.expects(:reject!).once.with('rejection' => 'other_reason')   # TODO: @offer.expects(:reject!).once
    post :reject, :id => @offer.id, :offer => { :rejection => 'other_reason' }
    assert_response :redirect
    assert_redirected_to offer_path(@offer)
    assert_equal @offer, assigns(:offer)
    assert_equal I18n.t("offer.action.reject", :offer => @offer.title), flash[:success]
  end
  
end