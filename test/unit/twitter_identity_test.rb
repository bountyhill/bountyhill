require_relative "../test_helper.rb"

class TwitterIdentityTest < ActiveSupport::TestCase
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
end
