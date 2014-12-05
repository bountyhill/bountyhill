# encoding: UTF-8

require_relative "../test_helper.rb"

class ShareTest < ActiveSupport::TestCase
  
  def test_fixture
    assert_difference("Comment.count") do
      Factory(:comment)
    end
  end

  def test_send_comment_mail
    commentable = Factory(:quest)
    commentator = Factory(:user)
    
    # owner of quest recieves email if other user comments
    Deferred.expects(:mail).once
    create_comment(:commentable => commentable, :owner => commentator, :body => "Foo Bar")
    
    # owner of quest recieves no email if he comments himself
    Deferred.expects(:mail).never
    create_comment(:commentable => commentable, :owner => commentable.owner, :body => "Foo Bar")
  end
  
  # def test_reward_commentor
  #   commentable = Factory(:quest)
  #   # TODO: commentable.owner.expects(:reward_for).with(commentable, :comment)
  #   User.any_instance.expects(:reward_for).with(commentable, :comment)
  #   Factory(:comment, :commentable => commentable)
  # end
  
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
  
private 
  def create_comment(attributes={})
    commentable = attributes.delete(:commentable)
    owner       = attributes.delete(:owner)
    comment = Comment.new(attributes)
    comment.commentable = commentable
    comment.owner       = owner
    comment.save!
  end
end