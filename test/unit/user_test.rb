require_relative "../test_helper.rb"

class UserTest < ActiveSupport::TestCase
  # There are no users without an identity
  def test_needs_an_identity
    assert_raise(ActiveRecord::RecordInvalid) {  
      User.create!
    }

    assert_nothing_raised() {  
      user = User.new
      user.identities << Factory(:identity, :user => user)
      user.save!
    }
  end
  
  # Delete a user's last identity deletes the user, too.
  def test_deleting_last_identity_deletes_user
    user = User.new
    user.identities << Factory(:identity)
    user.save!
    
    identity = user.identities.first
    identity.destroy
    
    assert_raise(ActiveRecord::RecordNotFound) {  
      user.reload
    }
  end
  
  # Can create a user and reads its identity
  def test_create_user
    user = Factory(:user)
    assert_kind_of(User, user)
    assert_kind_of(Identity::Email, user.identities.first)

    assert_kind_of(Identity::Email, user.identity(:email))
    assert_nil(user.identity(:twitter))
  end
end
