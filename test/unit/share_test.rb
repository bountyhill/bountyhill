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
    
    Factory(:twitter_identity, :user => owner)
    Identity::Twitter.any_instance.expects(:post).with("#{share.message}", :object => share.quest)
    owner.expects(:reward_for).with(share.quest, :share).once
    
    share.post(:twitter)
    assert share.identities[:twitter].kind_of?(Time)
  end
  
  def test_post_all
    share     = Factory(:share, :application => true)
    owner     = share.owner
    
    %w(twitter facebook linkedin xing).each do |identity|
      Factory("#{identity}_identity".to_sym,  :user => owner)
      "Identity::#{identity.camelize}".constantize.expects(:post).with("#{share.message}", :object => share.quest)
    end
    
    share.post_all
    assert share.shared_at.kind_of?(Time)
  end
  
end
