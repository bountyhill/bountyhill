require_relative "../../test_helper.rb"

class Identity::FacebookTest < ActiveSupport::TestCase
  def test_model_name
    assert_equal Identity::Facebook.model_name, Identity.model_name
  end
  
  def test_update_status
    facebook  = Identity::Facebook.new
    message   = "Hey hey hello Mary Lou"
    facebook.expects(:post).with("me", "feed", :message => message).once
    
    facebook.update_status(message)
  end
  
  def test_oauth_hash
    facebook = Identity::Facebook.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    oauth_hash = {
      :oauth_token      => "foo",
      :oauth_expires_at => Time.at(123456789),
    }

    assert_equal oauth_hash, facebook.send(:oauth_hash)
  end
  
  def test_post
    facebook = Identity::Facebook.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    message   = "Hey hey hello Mary Lou"
    Deferred.expects(:facebook).with("me", "feed", { :message => message }, facebook.send(:oauth_hash))

    facebook.send(:post, "me", "feed", :message => message)
  end
  
end