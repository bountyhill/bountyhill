# encoding: UTF-8

require_relative "../test_helper.rb"

class ShareTest < ActiveSupport::TestCase

  def test_fixture
    assert_difference("Share.count") do
      Factory(:share)
    end
  end

  def test_validations
    share = Factory(:share)
    assert share.valid?
    
    share.reload.quest = nil
    assert !share.valid?

    share.reload.owner = nil
    assert !share.valid?
    
    share.reload.message = nil
    assert !share.valid?

    share.reload.identities = {}
    assert !share.valid?

    share.reload.identities = {:foo => :bar}
    assert !share.valid?
    
    assert share.reload.valid?
  end
  
  def test_post
    share   = Factory(:share)
    owner   = share.owner
    twitter = Factory(:twitter_identity, :user => owner)
    # TODO: twitter.expects(:update_status).with("#{share.message}")
    Identity::Twitter.any_instance.expects(:update_status).with("#{share.message}")
    owner.expects(:reward_for).with(share.quest, :share).once
    
    share.post(:twitter)
    assert share.identities[:twitter].kind_of?(Time)
  end
  
end
