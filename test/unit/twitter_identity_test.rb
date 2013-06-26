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
  
  def test_can_save_and_update_oauth_attributes
    twitter = Identity::Twitter.create!(:identifier => "test", :oauth_secret => "foo", :oauth_token => "bar")

    assert_equal twitter.oauth_secret, "foo"
    assert_equal twitter.oauth_token, "bar"

    twitter = Identity::Twitter.find(twitter.id)
    assert_equal twitter.oauth_secret, "foo"
    assert_equal twitter.oauth_token, "bar"
  end
end
