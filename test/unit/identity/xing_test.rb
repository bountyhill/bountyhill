# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::XingTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Xing.model_name
    assert_equal "Identity::Xing", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_update_status
    xing  = Identity::Xing.new
    quest     = Factory(:quest)
    message   = "Hey hey hello Mary Lou"
    
    Deferred.expects(:xing).with(:create_status_message, "#{message} #{quest.url}", xing.send(:oauth_hash)).once
    xing.update_status(message, quest)
  end
  
  def test_oauth_hash
    xing    = Identity::Xing.new(:credentials => { :token => "foo", :secret => "bar" })
    oauth_hash  = {
      :consumer_key       => Bountybase.config.xing_app["consumer_key"],
      :consumer_secret    => Bountybase.config.xing_app["consumer_secret"],
      :oauth_token        => "foo",
      :oauth_token_secret => "bar"
    }

    assert_equal oauth_hash, xing.send(:oauth_hash)
  end
  
  def test_post
    xing = Identity::Xing.new
    message = "Hey hey hello Mary Lou"
    Deferred.expects(:xing).with(:create_status_message, message, xing.send(:oauth_hash))

    xing.send(:post, :create_status_message, message)
  end
end