# encoding: UTF-8

require_relative "../test_helper.rb"

class MessagesControllerTest < ActionController::TestCase

  def setup
    @controller = MessagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
    
    @sender   = Factory(:user)
    @identity = Factory(:twitter_identity, :email => "foo@bar.com", :credentials => { :token => "foo", :secret => "bar" })
    @quest    = Factory(:quest, 
      :owner      => @identity.user,
      :visibility =>'public',
      :bounty     => Money.new(12000, "EUR"),
      :started_at => Time.now,
      :expires_at => (Time.now + 1.month))
    
    login @sender
  end
  
  def test_new
    assert_no_difference "Message.count" do
      get :new, :message => {
        :reference_id   => @quest.id,
        :reference_type => @quest.class.name
      }
    end
    assert_response :success
    assert_template :new, :layout => 'dialog'
    assert assigns(:message)
    assert_equal @quest, assigns(:message).reference
  end
  
  def test_create
    assert_difference "Message.count" do
      post :create, :message => {
        :subject        => "Foo Bar",
        :body           => "Lorem ipsum",
        :reference_id   => @quest.id,
        :reference_type => @quest.class.name
      }
    end
    assert_response :redirect
    assert_redirected_to quest_path(@quest)
    assert assigns(:message)
    assert_equal @quest, assigns(:message).reference
    assert_equal I18n.t("notice.send.success", :record => assigns(:message).subject), flash[:success]
  end

  def test_create_fails
    assert_no_difference "Message.count" do
      xhr :post, :create, :message => {
        :reference_id   => @quest.id,
        :reference_type => @quest.class.name
      }
    end
    assert_response :success
    assert_template :create
    assert_equal 'text/javascript', @response.content_type
    assert assigns(:message)
    assert_equal @quest, assigns(:message).reference
  end
  
end