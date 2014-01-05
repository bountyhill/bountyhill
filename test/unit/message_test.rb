# encoding: UTF-8

require_relative "../test_helper.rb"

class MessageTest < ActiveSupport::TestCase
  def test_factory
    assert_difference("Message.count") do
      Message.any_instance.expects(:send_message)
      Factory(:message)
    end
  end

  def test_validation
    message = Message.new
    assert_false message.valid?
    
    message.subject = "foo bar"
    assert_false message.valid?
    
    message.body = "lorem ipsum"
    assert_false message.valid?
    
    message.sender = User.first
    assert_false message.valid?
    
    message.reference = Factory(:quest)
    assert message.valid?
  end
end