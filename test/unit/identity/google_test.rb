# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::GoogleTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Google.model_name
    assert_equal "Identity::Google", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_update_status
    google  = Identity::Google.new
    message = "Hey hey hello Mary Lou"
    google.expects(:post).with("TODO", :message => message).once
    
    google.update_status(message)
  end
  
  def test_oauth_hash
    google = Identity::Google.new(:credentials => { :token => "foo", :secret => "bar" })
    oauth_hash = {
      :oauth_token      => "foo",
      :oauth_secret     => "bar",
    }

    assert_equal oauth_hash, google.send(:oauth_hash)
  end
  
  def test_post
    google  = Identity::Google.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    message = "Hey hey hello Mary Lou"
    Deferred.expects(:google).with("me", "feed", { :message => message }, google.send(:oauth_hash))

    google.send(:post, "me", "feed", :message => message)
  end
  
end