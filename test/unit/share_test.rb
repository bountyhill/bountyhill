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
    
    # owner.expects(:reward_for).with(share.quest, :share)
    Share::IDENTITIES.each do |identity|
      Factory("#{identity}_identity".to_sym, :user => owner)
      share.owner.reload
      
      # test share within bountyhill's social network
      "Identity::#{identity.camelize}".constantize.expects(:post).with("#{share.message}", :object => share.quest)
      # test share within user's social network
      "Identity::#{identity.camelize}".constantize.any_instance.expects(:post).with("#{share.message}", :object => share.quest)
      
      share.post!(identity.to_sym)
      assert share.identities[identity].kind_of?(Time)
    end
  end
  
end
