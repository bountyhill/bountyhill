# encoding: UTF-8

require_relative "../test_helper.rb"

class UserTest < ActiveSupport::TestCase
  def create_user
    user = User.new
    identity = Identity::Email.new(:email => "e@mail.de", :password => "dummy-password", :name => "what")
    user.identities << identity
    user.save!
    user
  end

  def test_fixtures
    assert_equal 1, User.count
    assert_equal 1, Identity.count
    assert_equal 1, Identity::Twitter.count
    
    user = Identity::Twitter.find_by_identifier("radiospiel").user
    
    assert(user.admin?)
  end
  
  # There are no users without an identity
  def test_needs_an_identity
    assert_raise(ActiveRecord::RecordInvalid) {  
      User.create!
    }

    assert_difference "User.count", +1 do
      assert_difference "Identity.count", +1 do
        create_user
      end
    end
  end
  
  def test_factory
    assert_difference "User.count", +1 do
      assert_difference "Identity.count", +1 do
        assert_difference "Identity::Email.count", +1 do
          user = Factory(:user)
          assert_kind_of(User, user)
          assert user.valid?
        end
      end
    end
  end
  
  # Delete a user's last identity deletes the user, too.
  def test_deleting_last_identity_deletes_user
    user = User.find create_user.id
    
    identity = user.identities.first
    identity.destroy
    
    assert_raise(ActiveRecord::RecordNotFound) {  
      user.reload
    }
  end
  
  # Can create a user and reads its identity
  def test_create_user_with_random_id
    SecureRandom.stubs(:random_number).returns(1234567)
    
    user = Factory(:identity).user
    assert_kind_of(User, user)
    assert_equal(1234567, user.id)
  end
  
  def test_creating_user_sets_remember_token
    user = User.find(create_user.id)
    assert !user.remember_token.blank?

    assert_kind_of(Identity::Email, user.identity(:email))
    assert_nil(user.identity(:twitter))
  end

  def test_create_twitter_user
    SecureRandom.stubs(:random_number).returns(1234567)
    
    user = Factory(:twitter_identity, :identifier => "twark").user
    assert_kind_of(User, user)
    assert_equal(1234567, user.id)

    identity = user.identity(:twitter)
    assert_equal("twark", user.identifier)
  end

  def test_admin
    user = Factory(:twitter_identity, :identifier => "twark").user
    assert(!user.admin?)

    user = Identity::Twitter.find_by_identifier("radiospiel").user
    assert(user.admin?)
    
    assert User.admin.admin?
  end
  
  def test_pseudo_factories
    foo, bar = user("foo"), user("@bar")
    assert foo.identity(:twitter)
    assert !foo.identity?(:email)
    
    foo = user("foo@bar.com")
    assert !foo.identity(:twitter)
    assert foo.identity?(:email)
  end
  
  def test_name
    pend "TODO: add tests for name fallbacks!" do
      assert false
    end
  end
  
  def test_avatar
    email = "foo.bar@example.com"
    user  = User.new
    user.stubs(:email).returns(email)
    
    Gravatar.expects(:url).with(email, {})
    user.avatar
    
    pend "TODO: add more tests for avatar fallbacks!" do
      assert false
    end
  end
  
end
