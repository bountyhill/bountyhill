require_relative "../test_helper.rb"

class TwitterIdentityTest < ActiveSupport::TestCase
  def test_validation
    assert_invalid Identity::Twitter.new, :email
    Identity::Twitter.create!(:email => "test")
    assert_invalid Identity::Twitter.new(:email => "test"), :email
    assert_invalid Identity::Twitter.new(:email => "TeST"), :email

    assert_valid Identity::Twitter.new(:email => "name"), :email
    assert_invalid Identity::Twitter.new(:email => "@name"), :email
  end

  def test_screen_name
    twitter = Identity::Twitter.create!(:email => "test")
    assert_equal "test", twitter.screen_name
  end
  
  def test_can_save_and_update_oauth_attributes
    twitter = Identity::Twitter.create!(:email => "test", :oauth_secret => "foo", :oauth_token => "bar")

    assert_equal twitter.oauth_secret, "foo"
    assert_equal twitter.oauth_token, "bar"

    twitter = Identity::Twitter.find(twitter.id)
    assert_equal twitter.oauth_secret, "foo"
    assert_equal twitter.oauth_token, "bar"
  end
end
