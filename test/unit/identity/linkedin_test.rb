# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::LinkedinTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Linkedin.model_name
    assert_equal "Identity::Linkedin", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_set_expiration
    linkedin = Factory(:linkedin_identity)
    assert_nil linkedin.oauth_expires
    assert_nil linkedin.oauth_expires_at
    
    linkedin = Factory(:linkedin_identity, :extra => { "access_token" => nil })
    assert_nil linkedin.oauth_expires
    assert_nil linkedin.oauth_expires_at
    
    linkedin = Factory(:linkedin_identity, :extra => { "access_token" => OpenStruct.new(:params => { "oauth_expires_in" => 12345}) })
    assert linkedin.oauth_expires
    assert (Time.now.to_i + 12345) >= linkedin.oauth_expires_at
  end
  
  def test_api_accessible
    linkedin = Identity::Linkedin.new(:credentials => { :expires => false })
    assert_false linkedin.api_accessible?
    
    linkedin.credentials[:token] = "foo"
    assert_false linkedin.api_accessible?
    
    linkedin.credentials[:secret] = "bar"
    assert linkedin.api_accessible?
    
    linkedin.credentials[:expires] = true
    assert_false linkedin.api_accessible?
    
    linkedin.credentials[:expires_at] = (Time.now+1.hour).to_i
    assert_false linkedin.api_accessible?
    
    linkedin.credentials[:expires_at] = (Time.now+1.hour+1.minute).to_i
    assert linkedin.api_accessible?
  end
  
  def test_post
    linkedin    = Identity::Linkedin.new(:credentials => { :token => "foo", :secret => "bar" })
    message = "Hey hey hello Mary Lou"
    Identity::Linkedin.stubs(:message).returns(message)
    
    # test post for user
    Deferred.expects(:linkedin).with(:add_share, message, linkedin.send(:oauth_hash)).once
    linkedin.post(message)
    
    # test post for application
    Deferred.expects(:linkedin).with(:add_company_share, Bountybase.config.linkedin_app["page_id"], message, Identity::Linkedin.send(:oauth_hash)).once
    Identity::Linkedin.post(message)
  end

  def test_message
    text      = "Hey hey hello Mary Lou"
    message   = {
      :comment    => text,
      :visibility => {:code => 'anyone'}
    }
    
    # w/o object
    assert_equal message, Identity::Linkedin.message(text)
    
    # /w object
    quest = Factory(:quest)
    message = {
      :comment    => text,
      :visibility => {:code => 'anyone'},
      :content    => {
        :title                => quest.title,
        :description          => quest.description,
        :submitted_url        => quest.url,
        :submitted_image_url  => quest.images.first
      }
    }
    assert_equal message, Identity::Linkedin.message(text, quest)
  end  
  
  def test_oauth_hash
    linkedin = Identity::Linkedin.new(:credentials => { :token => "foo", :secret => "bar" })

    # test user's oauth hash
    oauth_hash = {
      :consumer_key       => Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret    => Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token        => "foo",
      :oauth_token_secret => "bar"
    }
    assert_equal oauth_hash, linkedin.send(:oauth_hash)
    
    # test app's oauth hash
    oauth_hash = {
      :consumer_key       => Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret    => Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token        => Bountybase.config.linkedin_app["oauth_token"],
      :oauth_token_secret => Bountybase.config.linkedin_app["oauth_secret"]
    }
    assert_equal oauth_hash, Identity::Linkedin.send(:oauth_hash)
  end
end