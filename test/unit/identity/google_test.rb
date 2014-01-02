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
    google  = Identity::Google.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    text    = "Hey hey hello Mary Lou"
    message = {
      :kind   => "plus#moment",
      :type   => "http://schemas.google.com/AddActivity",      
      :debug  => false,
      :target => {
        :kind => "plus#itemScope",
        :name => text }
    }

    Identity::Google.stubs(:message).returns(message)
    
    # test post for user
    Deferred.expects(:google).with({
      :api_method   => Identity::Google.send(:plus).moments.insert,
      :body_object  => message,
      :parameters   => { :collection => 'vault', :userId => 'me' }}, google.send(:oauth_hash)).once
    google.post(text)
    
    # test post for application
    # TODO: test google clint API here...
    Deferred.expects(:google).never
    Identity::Google.post(text)
  end

  def test_message
    text = "Hey hey hello Mary Lou"
    
    # w/o object
    message = {
      :kind   => "plus#moment",
      :type   => "http://schemas.google.com/AddActivity",
      :debug  => false,
      :target => {
        :kind => "plus#itemScope",
        :name => text }
    }
    google_msg = Identity::Google.message(text)
    google_msg[:target].delete(:id) # cannot compare randomly generated id
    assert_equal message, google_msg
    
    # /w object
    quest = Factory(:quest)
    message[:target].merge!({ :description => quest.description })
    google_msg = Identity::Google.message(text, quest)
    google_msg[:target].delete(:id) # cannot compare randomly generated id
    assert_equal message, google_msg
  end  
  
  def test_oauth_hash
    google = Identity::Google.new(:credentials => { :refresh_token => "foo", :expires_at => 123456789 })

    # test user's oauth hash
    oauth_hash = {
      :consumer_key         => Bountybase.config.google_app["consumer_key"],
      :consumer_secret      => Bountybase.config.google_app["consumer_secret"],
      :oauth_refresh_token  => "foo",
      :oauth_expires_at     => 123456789
    }
    
    assert_equal oauth_hash, google.send(:oauth_hash)
    
    # test app's oauth hash
    oauth_hash = {
      :consumer_key         => Bountybase.config.google_app["consumer_key"],
      :consumer_secret      => Bountybase.config.google_app["consumer_secret"],
      :oauth_refresh_token  => Bountybase.config.google_app["oauth_refresh_token"],
      :oauth_expires_at     => nil
    }
    assert_equal oauth_hash, Identity::Google.send(:oauth_hash)
  end
  
end