require_relative "../test_helper.rb"

class IdentityTest < ActiveSupport::TestCase
  # Can create a user and reads its identity
  def test_builds_a_user
    identity = Factory(:identity)
    
    assert_kind_of User, identity.user
    assert_equal Identity.find(identity.id).user, identity.user
  end
  
  # Can create a user and reads its identity
  def test_can_save_and_load_options
    identity = Factory(:identity)
    identity.options = { "a" => "b" }
    identity.save!
    
    r = identity.reload
    assert_equal({ "a" => "b" }, r.options)

    identity.options = nil
    identity.save!

    r = identity.reload
    assert_equal({}, r.options)
  end
end
