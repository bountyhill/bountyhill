# encoding: UTF-8

require_relative "../test_helper.rb"

class OfferTest < ActiveSupport::TestCase
  def quest
    unless @quest
      @quest = Factory(:quest)
      @quest.owner = Factory(:twitter_identity).user
    end
    
    @quest
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
    offer = Offer.new(:quest => quest.start!, :title => "Test title", :description => "This is a description")

    quest.stubs(:active?).returns(true)
    assert_activity_logged(:create,   offer)  { offer.save! }
    assert_activity_logged(:comment,  offer)  { Factory(:comment, :commentable => offer, :owner => offer.owner) }
  end
  
  def test_status
    offer = Offer.new(:quest => quest.start!, :title => "Test title", :description => "This is a description")
    
    Offer::STATES.reverse.each do |status|
      assert !offer.send("#{status}?"), "Offer's status ('#{offer.state}') should not equal ''#{status}'"
      offer.state = status
      assert offer.send("#{status}?"), "#Offer's status ('#{offer.state}') should equal '#{status}'"
    end
  end
  
  def test_outdated?
    offer = Offer.new(:quest => quest.start!, :title => "Test title", :description => "This is a description")
    assert !offer.outdated?
    
    offer.state = "active"
    assert !offer.outdated?

    offer.quest.expects(:active?).returns(false)
    assert offer.outdated?
  end
  
  def test_activate!
    offer = Offer.create(:quest => quest.start!, :title => "Test title", :description => "This is a description")

    # offer other then new cannot be activated
    offer.expects(:new?).returns(false)
    assert_raises RuntimeError do
      offer.activate!
    end

    # new offer can be activated
    offer.expects(:new?).returns(true)
    offer.owner.expects(:reward_for).with(offer, :activate)
    offer.activate!
    assert_equal "active", offer.state
  end

  def test_withdraw!
    offer = Offer.create(:quest => quest.start!, :title => "Test title", :description => "This is a description")
    
    # offer other then active cannot be withdrawn
    offer.expects(:active?).returns(false)
    assert_raises RuntimeError do
      offer.withdraw!
    end
    
    # active offer can be withdrawn
    offer.expects(:active?).returns(true)
    offer.owner.expects(:reward_for).with(offer, :withdraw)
    offer.withdraw!
    assert_equal "withdrawn", offer.state
  end
  
  def test_accept!
    offer = Offer.create(:quest => quest.start!, :title => "Test title", :description => "This is a description")
    
    # offer cannot be accepted by any other user then quest's owner
    offer.expects(:active?).returns(true)
    assert_raises RuntimeError do
      offer.accept!
    end

    as(offer.quest.owner) do
      # offer other then active cannot be accepted
      offer.expects(:active?).returns(false)
      assert_raises RuntimeError do
        offer.accept!
      end
      
      # active offer can be accepted
      offer.expects(:active?).returns(true)
      offer.quest.owner.expects(:reward_for).with(offer, :accept)
      offer.accept!
      assert_equal "accepted", offer.state
    end
  end
  
  def test_reject!
    offer = Offer.create(:quest => quest.start!, :title => "Test title", :description => "This is a description")
    
    # offer cannot be rejected by any other user then quest's owner
    offer.expects(:active?).returns(true)
    assert_raises RuntimeError do
      offer.reject!
    end
    
    as(offer.quest.owner) do
      # offer other then active cannot be rejected
      offer.expects(:active?).returns(false)
      assert_raises RuntimeError do
        offer.reject!
      end
    
      # active offer can be accepted
      offer.expects(:active?).returns(true)
      offer.quest.owner.expects(:reward_for).with(offer, :reject)
      offer.reject!
      assert_equal "rejected", offer.state
    end
  end
  
  def test_calculate_compliance
    offer = Offer.create(:quest => quest.start!, :title => "Test title", :description => "This is a description")
    assert_equal 50, offer.compliance
    
    offer.expects(:criteria).returns([{:compliance=>0}])
    assert_equal 0, offer.send(:calculate_compliance)

    offer.expects(:criteria).returns([{:compliance=>10}])
    assert_equal 100, offer.send(:calculate_compliance)

    offer.expects(:criteria).returns([{:compliance=>0}, {:compliance=>10}])
    assert_equal 50, offer.send(:calculate_compliance)

    offer.expects(:criteria).returns([
      {:compliance=>1},
      {:compliance=>2},
      {:compliance=>3},
      {:compliance=>4},
      {:compliance=>5},
      {:compliance=>6},
      {:compliance=>7},
      {:compliance=>8},
      {:compliance=>9},
      {:compliance=>10}])
    assert_equal 55, offer.send(:calculate_compliance)
  end
  
  def test_chain
    offer = Offer.create(:quest => quest.start!, :title => "Test title", :description => "This is a description")
    assert_equal [], offer.chain

    twitter = Factory(:twitter_identity, :identifier => "some_identifier")
    quest.expects(:chain_to).with(offer.owner).returns([twitter.identifier])
    assert_no_difference("Identity::Twitter.count") do
      assert_equal [twitter.user], offer.chain
    end
  end
end
