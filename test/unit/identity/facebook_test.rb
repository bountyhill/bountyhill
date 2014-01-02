# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::FacebookTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Facebook.model_name
    assert_equal "Identity::Facebook", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_post
    facebook  = Identity::Facebook.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    quest     = Factory(:quest)
    text      = "Hey hey hello Mary Lou"
    msg1      = Identity::Facebook.message(text)
    msg2      = Identity::Facebook.message(text, quest)
    
    # test post for user without object
    Deferred.expects(:facebook).with("me", "feed", msg1, facebook.send(:oauth_hash)).once
    facebook.post(text)

    # test post for user with object
    Deferred.expects(:facebook).with("me", "links", msg2, facebook.send(:oauth_hash)).once
    facebook.post(text, :object => quest)
    
    # test post for application without object
    Deferred.expects(:facebook).with(Bountybase.config.facebook_app["page_id"], "feed", msg1, Identity::Facebook.send(:oauth_hash)).once
    Identity::Facebook.post(text)

    # test post for application with object
    Deferred.expects(:facebook).with(Bountybase.config.facebook_app["page_id"], "links", msg2, Identity::Facebook.send(:oauth_hash)).once
    Identity::Facebook.post(text, :object => quest)
  end
  
  def test_message
    text     = "Hey hey hello Mary Lou"
    message  = {
      :message => text,
      :privacy => { 'value' => 'EVERYONE' }
    }
    
    # w/o object
    assert_equal message, Identity::Facebook.message(text)
    
    # /w object
    quest = Factory(:quest)
    message = {
      :message      => text,
      :link         => 'http://bountyhill.com',
      :name         => quest.title,
      :description  => quest.description,
      :picture      => quest.images.first,
      :privacy      => { 'value' => 'EVERYONE' }
    }
    
    assert_equal message, Identity::Facebook.message(text, quest)
  end
  
  def test_oauth_hash
    facebook = Identity::Facebook.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    
    # test user's oauth hash
    oauth_hash = {
      :oauth_token      => "foo",
      :oauth_expires_at => 123456789,
    }
    assert_equal oauth_hash, facebook.send(:oauth_hash)

    # test app's oauth hash
    oauth_hash = {
      :oauth_token      => Bountybase.config.facebook_app["page_token"],
      :oauth_expires_at => nil,
    }
    assert_equal oauth_hash, Identity::Facebook.send(:oauth_hash)
  end
end