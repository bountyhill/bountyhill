require_relative "../test_helper.rb"

class ActivityTest < ActiveSupport::TestCase

  def test_log
    quest = Factory(:quest)
    user  = quest.owner
    
    # activity don't know how to handle class comment
    assert_raise(ArgumentError) { Activity.log(user, :create, Comment.new) }

    # activity don't know how to handle action foo
    assert_raise(ArgumentError) { Activity.log(user, :foo, quest) }

    # activity logs creation of quest
    Bountybase.stubs :reward
    %w(create start stop comment forward).each do |action|
      assert_difference "Activity.count", +1 do
        activity = Activity.log(user, action, quest)
        assert_equal user, activity.user
        assert_equal action, activity.action
      end
    end
    
  end
end