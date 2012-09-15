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

  def test_read_visibilty
    foo_user = user("@foo")
    bar_user = user("@bar")

    Factory(:quest)

    as(foo_user) do
      Factory(:quest)
      Factory(:quest, :visibility => "public")
    end
    
    assert_equal 3, Quest.count
    
    as(foo_user) do
      assert_equal 2, Quest.count
    end
    
    as(nil) do
      assert_equal 1, Quest.count
    end

    as(bar_user) do
      assert_equal 1, Quest.count
    end

    assert_equal(admin, ActiveRecord::AccessControl.current_user)
  end

  def assert_cannot_write(object)
    assert_raise(ActiveRecord::RecordInvalid) {  
      object.update_attributes! "title" => "title #{rand(100000)}"
    }
  end

  def assert_can_write(object)
    assert_nothing_raised() {  
      object.update_attributes! "title" => "title #{rand(100000)}"
    }
  end
  
  def test_write_visibilty
    foo_user = user("@foo")
    bar_user = user("@bar")
  
    admin_quest = foo_quest = public_quest = nil
  
    admin_quest = Factory(:quest)
    as(foo_user) do
      foo_quest = Factory(:quest)
      public_quest = Factory(:quest, :visibility => "public")
    end
  
    # 
    
    assert_can_write admin_quest
    assert_can_write foo_quest
    assert_can_write public_quest
    
    as(foo_user) do
      assert_cannot_write admin_quest
      assert_can_write foo_quest
      assert_can_write public_quest
    end
    
    as(nil) do
      assert_cannot_write admin_quest
      assert_cannot_write foo_quest
      assert_cannot_write public_quest
    end
  
    as(bar_user) do
      assert_cannot_write admin_quest
      assert_cannot_write foo_quest
      assert_cannot_write public_quest
    end
  
    assert_equal(admin, ActiveRecord::AccessControl.current_user)
  end
end
