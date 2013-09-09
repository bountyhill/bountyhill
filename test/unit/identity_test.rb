# encoding: UTF-8

require_relative "../test_helper.rb"

class IdentityTest < ActiveSupport::TestCase

  # Can create a user and reads its identity
  def test_builds_a_user
    i = Factory(:email_identity)
    
    assert_kind_of User, i.user
    assert_equal Identity.find(i.id).user, i.user
  end
  
  # Can create a user and reads its identity
  def test_can_save_and_load_options
    identity = Factory(:email_identity)
    identity.serialized = { "a" => "b" }
    identity.save!
    
    r = identity.reload
    assert_equal({ "a" => "b" }, r.serialized)

    identity.serialized = nil
    identity.save!

    r = identity.reload
    assert_equal({}, r.serialized)
  end
  
  def test_activity_logging
    assert_activity_logged { Factory(:email_identity) }
    assert_activity_logged { Factory(:twitter_identity) }
  end
  
  def test_of_provider
    %w(twitter facebook).each do |provider|
      assert_equal "Identity::#{provider.camelize}", Identity.of_provider(provider).name
    end
  end

  # Delete a user's last identity soft deletes the user
  def test_soft_delete_user
    identity = Factory(:email_identity)
    identity.user.expects(:soft_delete!).once
    
    assert_difference("Identity.count", -1) do
      assert_no_difference("User.count") do
        identity.destroy
      end
    end
  end

end
