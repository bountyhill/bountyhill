# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::FacebookTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Facebook.model_name
    assert_equal "Identity::Facebook", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_update_status
    facebook  = Identity::Facebook.new
    quest     = Factory(:quest)
    message   = "Hey hey hello Mary Lou"
    facebook.expects(:post).with("me", "links", 
      :message => message,
      :link         => 'http://bountyhill.com',
      :name         => quest.title,
      :description  => quest.description,
      :picture      => quest.images.first,
      :privacy => {'value' => 'EVERYONE'}).once
    
    facebook.update_status(message, quest)
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