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
    
    # identifier mustbe uniw
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
    twitter.expects(:post).with(:follow, followee).once
    
    assert_nil twitter.followed_at
    twitter.follow!

    assert_not_nil twitter.followed_at
  end
  
  def test_update_status
    twitter = Identity::Twitter.new
    message = "Hey hey hello Mary Lou"
    twitter.expects(:post).with(:update, message).once
    
    twitter.update_status(message)
  end
  
  def test_direct_message
    twitter = Identity::Twitter.new(:info => { :nickname => "foo_bar" })
    message = "Hey hey hello Mary Lou"
    hermes  = User.hermes.identity(:twitter)
    hermes.expects(:post).with(:direct_message_create, twitter.handle, message)
    
    twitter.direct_message(message)
  end
  
  def test_oauth_hash
    twitter = Identity::Twitter.new(:credentials => { :secret => "foo", :token => "bar" })
    
    oauth_hash = {
      :consumer_secret    => Bountybase.config.twitter_app["consumer_secret"],
      :consumer_key       => Bountybase.config.twitter_app["consumer_key"],
      :oauth_token        => "bar",
      :oauth_token_secret => "foo"
    }

    assert_equal oauth_hash, twitter.send(:oauth_hash)
  end
  
  def test_post
    twitter = Identity::Twitter.new
    message = "Hey hey hello Mary Lou"
    Deferred.expects(:twitter).with(:update, message, twitter.send(:oauth_hash))

    twitter.send(:post, :update, message)
  end
end
