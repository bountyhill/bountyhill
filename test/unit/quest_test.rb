# encoding: UTF-8

require_relative "../test_helper.rb"

class QuestTest < ActiveSupport::TestCase
  def test_validation
    assert_invalid Quest.new, :title, :description, :bounty, :category

    # bounty
    assert_valid   Quest.new(:bounty => "12"), :bounty
    assert_invalid Quest.new(:bounty => "-12"), :bounty

    # test size limits
    quest = Quest.new(:bounty => "12", :title => "title", :description => "description", :category => "misc")
    quest.owner = admin

    assert_valid   quest
    assert_invalid Quest.new(:bounty => "12", :title => "title" * 100, :description => "description" * 1000), :title, :description
  end
  
  def test_activity_logging
    quest = Quest.new(:bounty => "12", :title => "title", :description => "description", :category => "misc")
    
    # assert_activity_logged(:create,   quest)  { quest.save! }
    assert_activity_logged(:start,    quest)  { quest.start! }
    assert_activity_logged(:stop,     quest)  { quest.stop! }
#    assert_activity_logged(:comment,  quest)  { Factory(:comment, :commentable => quest, :owner => quest.owner) }
  end
  
  def test_live_cycle
    quest = Factory(:quest, :owner => admin)

    # test start!
    quest.start!
    assert quest.started?
    assert quest.active?
    assert !quest.expired?

    # test run out
    quest.update_attribute(:expires_at, Time.new-1.day)
    assert quest.started?
    assert !quest.active?
    assert quest.expired?
    quest.update_attribute(:expires_at, Time.new+1.day)
    
    # test stop!
    quest.stop!
    assert quest.started?
    assert !quest.active?
    assert quest.expired?
  end
    
  def test_ownership
    quest = Quest.create!(:bounty => "12", :title => "title", :description => "description", :category => "misc")
    assert_valid quest
    assert_equal(admin, Quest.find(quest.id).owner)

    # needs a user. Note that the owner will be set when saving, not on #new!
    as(nil) do
      quest = Quest.new
      assert_nil(quest.owner)
      assert_invalid quest, :owner
    end
  end
  
  def test_owner_contactable_by
    user  = Factory(:user)
    quest = Factory(:quest, :owner => admin)
    
    assert_false quest.owner_contactable_by?(nil)
    assert_false quest.owner_contactable_by?(user)
    assert_false quest.owner_contactable_by?(quest.owner)
    
    # active quest's owner should be contactable by any user
    quest.start!
    assert        quest.active?
    assert_false  quest.offers.any?(&:accepted?)
    assert        quest.owner_contactable_by?(user)
    
    # quest's owner should be contactable by owner of accapted offer
    offer = Factory(:offer, :quest => quest, :owner => user, :state => 'active')
    as(admin) { offer.accept! }
    quest.reload.stop!
    assert_false  quest.active?
    assert        quest.offers.any?(&:accepted?)
    assert        quest.owner_contactable_by?(user)
  end
  
  def assert_cannot_write(*objects)
    objects.each do |object|
      assert_raise(ActiveRecord::RecordInvalid) {  
        object.update_attributes! "title" => "title #{rand(100000)}"
      }
    end
  end

  def assert_can_destroy(*objects)
    objects.each do |object|
      assert_nothing_raised() {  
        object.destroy
      }
    end
  end

  def assert_cannot_destroy(*objects)
    objects.each do |object|
      assert_raise(ActiveRecord::RecordInvalid) {  
        object.destroy
      }
    end
  end

  def assert_can_write(*objects)
    objects.each do |object|
      assert_nothing_raised() {  
        object.update_attributes! "title" => "title #{rand(100000)}"
      }
    end
  end

  def assert_cannot_read(*objects)
    objects.each do |object|
      assert_raise(ActiveRecord::RecordNotFound) {  
        Quest.find(object.id)
      }
    end
  end

  def assert_can_read(*objects)
    objects.each do |object|
      assert_nothing_raised() {  
        assert_equal(object, Quest.find(object.id))
      }
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

    assert_equal(admin, ActiveRecord.current_user)
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

    assert_equal(admin, ActiveRecord.current_user)
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
