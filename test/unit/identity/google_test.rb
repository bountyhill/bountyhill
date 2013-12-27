# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::GoogleTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Google.model_name
    assert_equal "Identity::Google", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_post
    google    = Identity::Google.new(:credentials => { :token => "foo", :secret => "bar" })
    message = "Hey hey hello Mary Lou"
    Identity::Google.stubs(:message).returns(message)
    
    # test post for user
    Deferred.expects(:google).with("TODO", message, google.send(:oauth_hash)).once
    google.post(message)
    
    # test post for application
    Deferred.expects(:google).with("TODO", message, Identity::Google.send(:oauth_hash)).once
    Identity::Google.post(message)
  end

  def test_message
    text    = "Hey hey hello Mary Lou"
    
    # w/o object
    message = { :message => text }
    assert_equal message, Identity::Google.message(text)
    
    # /w object
    quest = Factory(:quest)
    message = {
      :message      => text,
      :link         => 'http://bountyhill.com',
      :name         => quest.title,
      :description  => quest.description,
      :picture      => nil
    }
    assert_equal message, Identity::Google.message(text, quest)
  end  
  
  def test_oauth_hash
    google = Identity::Google.new(:credentials => { :token => "foo", :secret => "bar" })

    # test user's oauth hash
    oauth_hash = {
      :consumer_key     => Bountybase.config.google_app["consumer_key"],
      :consumer_secret  => Bountybase.config.google_app["consumer_secret"],
      :oauth_token      => "foo",
      :oauth_secret     => "bar"
    }
    assert_equal oauth_hash, google.send(:oauth_hash)
    
    # test app's oauth hash
    oauth_hash = {
      :consumer_key     => Bountybase.config.google_app["consumer_key"],
      :consumer_secret  => Bountybase.config.google_app["consumer_secret"],
      :oauth_token      => Bountybase.config.google_app["oauth_token"],
      :oauth_secret     => Bountybase.config.google_app["oauth_secret"]
    }
    assert_equal oauth_hash, Identity::Google.send(:oauth_hash)
  end
  
end