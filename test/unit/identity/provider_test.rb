# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::ProviderTest < ActiveSupport::TestCase

  def test_find_or_create_unknown_provider
    assert_raise(RuntimeError) {
      Identity::Facebook.find_or_create("foobar", nil, "provider" => "foobar")
    }
  end
  
  def test_find_or_create_known_identity
    fb  = Factory(:facebook_identity, :identifier => "foobar")
    usr = fb.user
    
    assert_no_difference "Identity::Facebook.count" do
      assert_no_difference "User.count" do
        fb_found = Identity::Facebook.find_or_create("foobar", nil, "provider" => "facebook")
        assert_equal fb, fb_found
        assert_equal usr, fb_found.user
      end
    end
  end

  def test_find_or_create_known_identity_with_differnt_suer
    fb    = Factory(:facebook_identity, :identifier => "foobar")
    user  = Factory(:user)
    
    assert_no_difference "Identity::Facebook.count" do
      assert_no_difference "User.count" do
        fb_found = Identity::Facebook.find_or_create("foobar", user, "provider" => "facebook")
        assert_equal fb, fb_found
        assert_equal user, fb_found.user
      end
    end
  end

  def test_find_or_create_unknown_identity
    assert_difference "Identity::Facebook.count" do
      assert_difference "User.count" do
        fb_found = Identity::Facebook.find_or_create("foobar", nil, "provider" => "facebook")
        assert_equal "foobar", fb_found.identifier
        assert fb_found.user.present?
      end
    end
  end
  
  def test_info_attributes
    t = Identity::Twitter.new(:identifier => "foobar", :info => {
      :name         => "name",
      :email        => "email",
      :nickname     => "nickname",
      :first_name   => "first_name",
      :last_name    => "last_name",
      :location     => "location",
      :description  => "description",
      :image        => "image",
      :phone        => "phone",
      :urls         => "urls"
    })
    
    %w(name email nickname first_name last_name location description image phone urls).each do |info|
      assert_equal info, t.send(info)
    end
  end
  
  def test_credential_attributes
    t = Identity::Twitter.new(:identifier => "foobar", :credentials => {
      :secret     => "secret",
      :token      => "token",
      :expires    => "expires",
      :expires_at => "expires_at"
    })
    
    %w(secret token expires expires_at).each do |credential|
      assert_equal credential, t.send("oauth_#{credential}")
    end
  end
  
  def test_avatar
    t = Identity::Twitter.new(:identifier => "foobar")
    assert_equal nil,   t.avatar
    assert_equal "foobar",  t.avatar(:default => "foobar")
    
    t.info = { :image => "image" }
    assert_equal "image",   t.avatar
    assert_equal "image",  t.avatar(:default => "foobar")
  end
  
  def test_identity_provider?
    tw = Identity::Twitter.new(:identifier => "foobar")
    assert tw.identity_provider?
    assert tw.respond_to?(:name)
    assert tw.respond_to?(:avatar)
    
    fb  = Identity::Facebook.new(:identifier => "foobar")
    assert fb.identity_provider?
    assert fb.respond_to?(:name)
    assert fb.respond_to?(:avatar)
  end
  
end