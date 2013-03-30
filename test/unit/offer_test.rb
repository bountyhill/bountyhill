require_relative "../test_helper.rb"

class OfferTest < ActiveSupport::TestCase
  def quest
    @quest ||= Factory(:quest)
  end
  
  def test_validation_fails_when_quest_is_not_yet_started
    # quest not yet started 
    assert_invalid Offer.new(:quest => quest), :description, :base
  end
  
  def test_validation
    quest.start!
    
    assert_invalid Offer.new, :title, :description, :quest

    # quest
    assert_valid   Offer.new(:quest => quest), :quest

    # title
    assert_valid   Offer.new(:title => "Test title"), :title

    # description
    assert_valid   Offer.new(:quest => quest, :title => "Test title", :description => "This is a description")
    assert_invalid Offer.new(:description => "This is a description" * 200), :description

    # needs a user. Note that the owner will be set when saving, not on #new!
    as(nil) do
      offer = Offer.new
      assert_nil(offer.owner)
      assert_invalid offer, :owner
    end
  end
  
  def test_activities
    offer = Offer.new(:quest => quest, :title => "Test title", :description => "This is a description")
    quest.stubs(:active?).returns(true)
    offer.stubs(:active?).returns(true)

    assert_activity_logged(offer, :create)    { offer.save! }
    assert_activity_logged(offer, :withdraw)  { offer.withdraw! }
    assert_activity_logged(offer, :accept)    { offer.accept! }
    assert_activity_logged(offer, :reject)    { offer.reject! }
    assert_activity_logged(offer, :comment)   { Factory(:comment, :commentable => offer, :owner => offer.owner) }
  end
end

__END__
  
  def test_ownership
    quest = Offer.create!(:bounty => "12", :title => "title", :description => "description")
    assert_valid quest
    assert_equal(admin, Offer.find(Offer.id).owner)

    # needs a user. Note that the owner will be set when saving, not on #new!
    as(nil) do
      quest = Offer.new
      assert_nil(Offer.owner)
      assert_invalid quest, :owner
    end
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
        Offer.find(object.id)
      }
    end
  end

  def assert_can_read(*objects)
    objects.each do |object|
      assert_nothing_raised() {  
        assert_equal(object, Offer.find(object.id))
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

    assert_equal false, foo_Offer.started?

    as(nil) do
      assert_cannot_read foo_quest
    end
    
    foo_Offer.start!
    assert_equal true, foo_Offer.started?

    as(nil) do
      assert_can_read foo_quest
    end
  end
end
