require_relative "../test_helper.rb"

class QuestAccessControlTest < ActiveSupport::TestCase
  attr_reader :foo_user, :bar_user
  attr_reader :admin_quest, :foo_quest, :public_quest
  
  def setup
    super
    
    @foo_user = user("@foo")
    @bar_user = user("@bar")
  
    @admin_quest = Factory(:quest)
    as(foo_user) do
      @foo_quest = Factory(:quest)
      @public_quest = Factory(:quest, :visibility => "public")
    end
  end
  
  def test_read_visibilty
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

    assert_equal(admin, ActiveRecord.current_user)
  end

  def test_write_visibilty
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
  
    assert_equal(admin, ActiveRecord.current_user)
  end
  
  def test_destroy_access_control_1
    assert_can_destroy admin_quest, foo_quest, public_quest
  end
  
  def test_destroy_access_control_2
    as(foo_user) do
      assert_cannot_destroy admin_quest
      assert_can_destroy foo_quest, public_quest
    end
  end
  
  def test_destroy_access_control_3
    as(nil) do
      assert_cannot_destroy admin_quest, foo_quest, public_quest
    end
  end
  
  def test_destroy_access_control_4
    as(bar_user) do
      assert_cannot_destroy admin_quest, foo_quest, public_quest
    end
  end
  
  def test_publish
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
