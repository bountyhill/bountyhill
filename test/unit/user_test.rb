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
    # user has first_name and/or last_name set
    user = Factory(:user, :first_name => "Foo", :last_name => "Bar")
    assert_equal "Foo Bar", user.name
    
    # user has not first_name and/or last_name set, but email identity with name
    user.update_attributes(:first_name => nil, :last_name => nil)
    user.identity(:email).update_attributes(:name => "Bar Foo")
    assert_equal "Bar Foo", user.name

    # user has not first_name and/or last_name set and no email identity with name
    user.identity(:email).update_attributes(:name => nil)
    user.identities << Identity::Twitter.new(:identifier => "834u5429p8u498u40i6")
    user.identity(:twitter).stubs(:name).returns("Far Boo")
    assert_equal "Far Boo", user.name
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
  
  def test_confirm_email!
    user = Factory(:user)
    assert user.identity(:email)
    assert !user.identity(:confirmed)
    
    user.confirm_email!
    
    assert user.identity(:email)
    assert user.identity(:confirmed)
  end
  
  def test_confirmed_email
    user = Factory(:user)
    user.confirm_email!

    assert_equal user.identity(:confirmed).email, user.confirmed_email
  end

  def test_transfer!
    owner     = Factory(:user)
    quest     = Factory(:quest, :owner => owner)
    new_owner = ActiveRecord.current_user
    
    assert_equal owner, quest.reload.owner
    assert quest.owner != new_owner
    quest.owner.stubs(:draft?).returns(true)

    assert_no_difference("User.count") do
      User.transfer! quest => new_owner
    end
    
    assert_equal new_owner, quest.reload.owner
  end
  
  def test_soft_delete!
    user = User.new
    user.identities << (Identity::Twitter.new   :identifier => "23485z948u4294564366")
    user.identities << (Identity::Facebook.new  :identifier => "392459ht2hg24p97gh49")
    user.identities << (Identity::Email.new     :email => "foo@bar.com", :password => "foobar", :password_confirmation => "foobar")
    user.save!

    assert_no_difference("User.count") do
      assert_difference("Identity.count", -2) do
        user.soft_delete!
      end
    end
    assert(identity = user.reload.identities.first)
    assert identity.kind_of?(Identity::Deleted)
    assert_equal "foo@bar.com", identity[:email]
  end

  def test_inspect
    user = User.new
    user.expects(:id).returns(123)
    assert_equal "#<User id: #{123} []>", user.inspect
  end

  def test_inspect_with_identity_twitter
    user = User.new
    user.expects(:id).returns(123)
    twitter = Identity::Twitter.new
    twitter.expects(:handle).returns("foo_bar")
    user.identities = [twitter]
    assert_equal "#<User id: #{123} [t:foo_bar]>", user.inspect
  end
  
  def test_inspect_with_identity_facebook
    user = User.new
    user.expects(:id).returns(123)
    facebook = Identity::Facebook.new
    facebook.expects(:nickname).returns("Foo Bar")
    user.identities = [facebook]
    assert_equal "#<User id: #{123} [f:Foo Bar]>", user.inspect
  end
  
  def test_inspect_with_identity_email
    user = User.new
    user.expects(:id).returns(123)
    email = Identity::Email.new
    email.expects(:confirmed?).returns(false)
    email.expects(:email).returns("foo@bar.com")
    user.identities = [email]
    assert_equal "#<User id: #{123} [@:foo@bar.com (-)]>", user.inspect
  end
  
  def test_inspect_with_identity_confirmed
    user = User.new
    user.expects(:id).returns(123)
    email = Identity::Email.new
    email.expects(:confirmed?).returns(true)
    email.expects(:email).returns("foo@bar.com")
    user.identities = [email]
    assert_equal "#<User id: #{123} [@:foo@bar.com (✓)]>", user.inspect
  end
  
  def test_inspect_with_identity_deleted
    user = User.new
    user.expects(:id).returns(123)
    deleted = Identity::Deleted.new
    user.identities = [deleted]
    assert_equal "#<User id: #{123} [---deleted---]>", user.inspect
  end
  
end
