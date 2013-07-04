require_relative "../test_helper.rb"

load "spec/factories.rb"

class LiabilityTest < ActiveSupport::TestCase

  def test_create_liability
    foo, bar, baz = user("foo"), user("@bar"), user("baz")
    reference = foo
    
    Liability.generate Money.new(1000, Money.default_currency), foo => bar, :reference => reference
    
    assert_equal -1000, foo.reload.account.balance.cents
    assert_equal 1000, bar.reload.account.balance.cents

    Liability.generate Money.new(200, Money.default_currency), bar => baz, :reference => reference

    assert_equal -1000, foo.reload.account.balance.cents
    assert_equal 800, bar.reload.account.balance.cents
    assert_equal 200, baz.reload.account.balance.cents
  end

  def test_only_accepted_offers_can_be_balanced
    quest = Factory(:quest)
    quest.start!
    offer = Factory(:offer, :quest => quest)
    assert_raise(ArgumentError) {  
      Account.balance offer
    }
  end
  
  def test_balance_offer
    foo, bar, baz = user("foo"), user("bar"), user("baz")
    owner, offerer = user("owner"), user("offerer")
    
    quest = Factory(:quest, :owner => owner, :bounty => Money.new(12000, "EUR"))
    quest.start!
    offer = Factory(:offer, :quest => quest, :owner => offerer, :state => "active")
    offer.accept!
    offer.stubs(:chain).returns([foo, bar, baz])
    Account.balance offer
    
    assert_equal -12000, owner.account.balance.cents
    assert_equal 6000, offerer.account.balance.cents
    assert_equal 1600, foo.account.balance.cents
    assert_equal 1600, bar.account.balance.cents
    assert_equal 1600, baz.account.balance.cents
    assert_equal 1200, User.admin.account.balance.cents
  end
end

__END__
  
    foo, bar, baz = user("foo"), user("@bar"), user("baz")
    reference = foo
    
    Liability.generate Money.new(1000, Money.default_currency), foo => bar, :reference => reference
    
    assert_equal -1000, foo.reload.account.balance.cents
    assert_equal 1000, bar.reload.account.balance.cents

    Liability.generate Money.new(200, Money.default_currency), bar => baz, :reference => reference

    assert_equal -1000, foo.reload.account.balance.cents
    assert_equal 800, bar.reload.account.balance.cents
    assert_equal 200, baz.reload.account.balance.cents
  end
end
