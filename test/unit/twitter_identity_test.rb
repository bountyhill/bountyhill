require_relative "../test_helper.rb"

class TwitterIdentityTest < ActiveSupport::TestCase
  def test_validation
    assert_invalid Identity::Twitter.new, :name
    Identity::Twitter.create!(:name => "test")
    assert_invalid Identity::Twitter.new(:name => "test"), :name
    assert_invalid Identity::Twitter.new(:name => "TeST"), :name

    assert_valid Identity::Twitter.new(:name => "name"), :name
    assert_invalid Identity::Twitter.new(:name => "@name"), :name
  end

  def test_screen_name
    twitter = Identity::Twitter.create!(:name => "test")
    assert_equal "@test", twitter.screen_name
  end
  
  def test_can_save_and_update_oauth_attributes
    twitter = Identity::Twitter.create!(:name => "test", :oauth_secret => "foo", :oauth_token => "bar")

    assert_equal twitter.oauth_secret, "foo"
    assert_equal twitter.oauth_token, "bar"

    twitter = Identity::Twitter.find(twitter.id)
    assert_equal twitter.oauth_secret, "foo"
    assert_equal twitter.oauth_token, "bar"
  end
end
