# encoding: UTF-8

require_relative "../test_helper.rb"

class ActivityTest < ActiveSupport::TestCase

  def test_log
    quest = Factory(:quest)
    quest.start!
    offer = Factory(:offer, :quest => quest, :state => 'active')
    user  = quest.owner
    
    # activity don't know how to handle class comment
    assert_raise(ArgumentError) { Activity.log(user, :create, Comment.new) }

    # activity don't know how to handle action foo
    assert_raise(ArgumentError) { Activity.log(user, :foo, quest) }

    # activity logs actions on quest
    Bountybase.stubs :reward
    %w(start stop share).each do |action|
      assert_difference "Activity.count", +1 do
        activity = Activity.log(user, action, quest)
        assert_equal user, activity.user
        assert_equal action, activity.action
      end
    end

    # activity logs actions on offer
    Bountybase.stubs :reward
    %w(activate accept withdraw).each do |action|
      assert_difference "Activity.count", +1 do
        activity = Activity.log(user, action, offer)
        assert_equal user, activity.user
        assert_equal action, activity.action
      end
    end
    
    # activity logs actions on identity
    Bountybase.stubs :reward
    %w(create delete).each do |action|
      assert_difference "Activity.count", +1 do
        activity = Activity.log(user, action, user.identities.first)
        assert_equal user, activity.user
        assert_equal action, activity.action
      end
    end
  end
end