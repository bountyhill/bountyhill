# encoding: UTF-8

require_relative "../test_helper.rb"

class ShareTest < ActiveSupport::TestCase
  
  def test_fixture
    assert_difference("Comment.count") do
      Factory(:comment)
    end
  end
  
  def test_reward_commentor
    commentable = Factory(:quest)
    # TODO: commentable.owner.expects(:reward_for).with(commentable, :comment)
    User.any_instance.expects(:reward_for).with(commentable, :comment)
    Factory(:comment, :commentable => commentable)
  end
  
  def test_writable?
    comment = Factory(:comment)

    # false if no user given
    assert !comment.writable?(Factory(:user))
    
    # true for admins
    assert comment.writable?(User.admin)
    
    # true for owner
    assert comment.writable?(comment.owner)
    
    # true for commentable's owner
    assert comment.writable?(comment.commentable.owner)
  end
  
end