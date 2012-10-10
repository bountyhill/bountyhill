# encoding: utf-8

require_relative "../test_helper.rb"

class MoneyTest < ActiveSupport::TestCase
  def test_to_s
    money = Money.new(265376578, "EUR")
    assert_equal "€ 2.653.765,78", money.to_s
    assert_equal "2.653.765,78", money.to_s(currency: false)
    assert_equal "€ 2.653.766", money.to_s(cents: false)
    assert_equal "€ 2653765,78", money.to_s(thousands_separators: false)
    assert_equal "2653766", money.to_s(currency: false, cents: false, thousands_separators: false)
  end
end
