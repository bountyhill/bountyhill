# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::LinkedinTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Linkedin.model_name
    assert_equal "Identity::Linkedin", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_update_status
    linkedin  = Identity::Linkedin.new
    quest     = Factory(:quest)
    message   = "Hey hey hello Mary Lou"
    
    linkedin.expects(:post).with(:add_share, 
      :comment    => message,
      :visibility => {:code => 'anyone'},
      :content    => {
        :title                => quest.title,
        :description          => quest.description,
        :submitted_url        => quest.url,
        :submitted_image_url  => quest.images.first}).once
    linkedin.update_status(message, quest)
  end
  
  def test_oauth_hash
    linkedin    = Identity::Linkedin.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    oauth_hash  = {
      :consumer_key       => Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret    => Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token        => "foo",
      :oauth_token_secret => nil
    }

    assert_equal oauth_hash, linkedin.send(:oauth_hash)
  end
  
  def test_post
    linkedin  = Identity::Linkedin.new(:credentials => { :token => "foo", :expires_at => 123456789 })
    message   = "Hey hey hello Mary Lou"
    Deferred.expects(:linkedin).with("me", "feed", { :message => message }, linkedin.send(:oauth_hash))

    linkedin.send(:post, "me", "feed", :message => message)
  end
  
end