# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::XingTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Xing.model_name
    assert_equal "Identity::Xing", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_post
    xing    = Identity::Xing.new(:credentials => { :token => "foo", :secret => "bar" })
    message = "Hey hey hello Mary Lou"
    Identity::Xing.stubs(:message).returns(message)
    
    # test post for user
    Deferred.expects(:xing).with(:create_status_message, message, xing.send(:oauth_hash)).once
    xing.post(message)
    
    # test post for application
    Deferred.expects(:xing).with(:create_status_message, message, Identity::Xing.send(:oauth_hash)).once
    Identity::Xing.post(message)
  end

  def test_message
    text  = "Hey hey hello Mary Lou"
    
    # w/o object
    assert_equal text, Identity::Xing.message(text)
    
    # /w object
    quest = Factory(:quest)
    assert_equal "#{text} #{quest.url}", Identity::Xing.message(text, quest)
  end  
  
  def test_oauth_hash
    xing = Identity::Xing.new(:credentials => { :token => "foo", :secret => "bar" })

    # test user's oauth hash
    oauth_hash = {
      :consumer_key       => Bountybase.config.xing_app["consumer_key"],
      :consumer_secret    => Bountybase.config.xing_app["consumer_secret"],
      :oauth_token        => "foo",
      :oauth_token_secret => "bar"
    }
    assert_equal oauth_hash, xing.send(:oauth_hash)
    
    # test app's oauth hash
    oauth_hash = {
      :consumer_key       => Bountybase.config.xing_app["consumer_key"],
      :consumer_secret    => Bountybase.config.xing_app["consumer_secret"],
      :oauth_token        => Bountybase.config.xing_app["oauth_token"],
      :oauth_token_secret => Bountybase.config.xing_app["oauth_secret"]
    }
    assert_equal oauth_hash, Identity::Xing.send(:oauth_hash)
  end
end