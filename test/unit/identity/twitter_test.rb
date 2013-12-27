# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::TwitterTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Twitter.model_name
    assert_equal "Identity::Twitter", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_validation
    # identifier cannot be nil
    assert_invalid Identity::Twitter.new, :identifier
    
    # identifier must be uniq
    assert_valid   Identity::Twitter.create!(:identifier => "test")
    assert_invalid Identity::Twitter.new(:identifier => "test"), :identifier
    assert_invalid Identity::Twitter.new(:identifier => "TeST"), :identifier
  end
  
  def test_can_save_and_update_credentials
    twitter = Identity::Twitter.create!(:identifier => "test", :credentials => { :secret => "foo", :token => "bar" })
    assert_equal "foo", twitter.oauth_secret
    assert_equal "bar", twitter.oauth_token

    twitter = Identity::Twitter.find(twitter.id)
    assert_equal "foo", twitter.oauth_secret
    assert_equal "bar", twitter.oauth_token
  end
  
  def test_handle
    twitter = Identity::Twitter.new(:info => { :nickname => "foo_bar" })
    assert_equal "foo_bar", twitter.handle
    assert_equal "foo_bar", twitter.screen_name
  end
  
  def test_follow
    twitter = Identity::Twitter.new
    twitter.expects(:follow!).once
    assert twitter.follow
    
    twitter.expects(:followed_at?).once.returns(true)
    assert_false twitter.follow
  end
  
  def test_follow!
    twitter   = Identity::Twitter.create!(:identifier => "test")
    followee  = Bountybase.config.twitter_notifications["user"]
    Deferred.expects(:twitter).with(:follow, followee, twitter.send(:oauth_hash)).once
    
    assert_nil twitter.followed_at
    twitter.follow!

    assert_not_nil twitter.followed_at
  end
  
  def test_direct_message
    twitter = Identity::Twitter.new(:info => { :nickname => "foo_bar" })
    message = "Hey hey hello Mary Lou"
    hermes  = User.hermes.identity(:twitter)
    Deferred.expects(:twitter).with(:direct_message_create, twitter.handle, message, hermes.send(:oauth_hash))
    
    twitter.direct_message(message)
  end
  
  def test_post
    twitter = Identity::Twitter.new(:credentials => { :token => "foo", :secret => "bar" })
    message = "Hey hey hello Mary Lou"
    twitter.stubs(:message).returns(message)
    
    # test post for user
    Deferred.expects(:twitter).with(:update, message, twitter.send(:oauth_hash)).once
    twitter.post(message)
    
    # test post for application
    Deferred.expects(:twitter).with(:update, message, Identity::Twitter.send(:oauth_hash)).once
    Identity::Twitter.post(message)
  end
  
  def test_message
    text  = "Hey hey hello Mary Lou"
    
    # w/o object
    assert_equal text, Identity::Twitter.message(text)
    
    # /w object
    quest = Factory(:quest)
    assert_equal "#{text} #{quest.url}", Identity::Twitter.message(text, quest)
  end  
  
  def test_oauth_hash
    twitter = Identity::Twitter.new(:credentials => { :token => "foo", :secret => "bar" })

    # test user's oauth hash
    oauth_hash = {
      :consumer_key       => Bountybase.config.twitter_app["consumer_key"],
      :consumer_secret    => Bountybase.config.twitter_app["consumer_secret"],
      :oauth_token        => "foo",
      :oauth_token_secret => "bar"
    }
    assert_equal oauth_hash, twitter.send(:oauth_hash)
    
    # test app's oauth hash
    oauth_hash = {
      :consumer_key       => Bountybase.config.twitter_app["consumer_key"],
      :consumer_secret    => Bountybase.config.twitter_app["consumer_secret"],
      :oauth_token        => Bountybase.config.twitter_app["oauth_token"],
      :oauth_token_secret => Bountybase.config.twitter_app["oauth_secret"]
    }
    assert_equal oauth_hash, Identity::Twitter.send(:oauth_hash)
  end
end
