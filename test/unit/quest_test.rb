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

  attr_reader :foo_user, :bar_user
  attr_reader :admin_quest, :foo_quest, :public_quest
  
  def setup_visibility
    @foo_user = user("@foo")
    @bar_user = user("@bar")
  
    @admin_quest = Factory(:quest)
    as(foo_user) do
      @foo_quest = Factory(:quest)
      @public_quest = Factory(:quest, :visibility => "public")
    end
  end
  
  def test_read_visibilty
    setup_visibility

    assert_can_read admin_quest, foo_quest, public_quest
    
    as(foo_user) do
      assert_cannot_read admin_quest
      assert_can_read foo_quest, public_quest
    end
    
    as(nil) do
      assert_cannot_read admin_quest, foo_quest
      assert_can_read public_quest
    end

    as(bar_user) do
      assert_cannot_read admin_quest, foo_quest
      assert_can_read public_quest
    end

    assert_equal(admin, ActiveRecord::AccessControl.current_user)
  end

  def test_write_visibilty
    setup_visibility

    assert_can_write admin_quest, foo_quest, public_quest
    
    as(foo_user) do
      assert_cannot_write admin_quest
      assert_can_write foo_quest, public_quest
    end
    
    as(nil) do
      assert_cannot_write admin_quest, foo_quest, public_quest
    end
  
    as(bar_user) do
      assert_cannot_write admin_quest, foo_quest, public_quest
    end
  
    assert_equal(admin, ActiveRecord::AccessControl.current_user)
  end
  
  def test_destroy_access_control
    setup_visibility

    assert_can_destroy admin_quest, foo_quest, public_quest
    
    setup_visibility

    as(foo_user) do
      assert_cannot_destroy admin_quest
      assert_can_destroy foo_quest, public_quest
    end
    
    setup_visibility

    as(nil) do
      assert_cannot_destroy admin_quest, foo_quest, public_quest
    end
  
    setup_visibility

    as(bar_user) do
      assert_cannot_destroy admin_quest, foo_quest, public_quest
    end
  end
  
  def test_publish
    setup_visibility

    assert_equal false, foo_quest.started?

    as(nil) do
      assert_cannot_read foo_quest
    end
    
    foo_quest.start!
    assert_equal true, foo_quest.started?

    as(nil) do
      assert_can_read foo_quest
    end
  end
end
