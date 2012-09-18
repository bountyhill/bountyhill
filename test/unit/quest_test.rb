require_relative "../test_helper.rb"

class QuestTest < ActiveSupport::TestCase
  def test_validation
    assert_invalid Quest.new, :title, :description, :bounty

    # bounty
    assert_valid   Quest.new(:bounty => "12"), :bounty
    assert_invalid Quest.new(:bounty => "-12"), :bounty

    # test size limits
    quest = Quest.new(:bounty => "12", :title => "title", :description => "description")
    quest.owner = admin

    assert_valid   quest
    assert_invalid Quest.new(:bounty => "12", :title => "title" * 100, :description => "description" * 1000), :title, :description
  end
  
  def test_ownership
    quest = Quest.create!(:bounty => "12", :title => "title", :description => "description")
    assert_valid quest
    assert_equal(admin, Quest.find(quest.id).owner)

    # needs a user. Note that the owner will be set when saving, not on #new!
    as(nil) do
      quest = Quest.new
      assert_nil(quest.owner)
      assert_invalid quest, :owner
    end
  end
end
