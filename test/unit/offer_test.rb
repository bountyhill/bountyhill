# encoding: UTF-8

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
  
  def test_activity_logging
    offer = Offer.new(:quest => quest, :title => "Test title", :description => "This is a description")

    quest.stubs(:active?).returns(true)
    assert_activity_logged(:create,   offer)  { offer.save! }
    assert_activity_logged(:activate, offer)  { offer.activate! }
    assert_activity_logged(:withdraw, offer)  { offer.withdraw! }
    
    offer.stubs(:active?).returns(true)
    assert_activity_logged(:accept,   offer)  { offer.accept! }
    assert_activity_logged(:reject,   offer)  { offer.reject! }
    assert_activity_logged(:comment,  offer)  { Factory(:comment, :commentable => offer, :owner => offer.owner) }
  end
end
