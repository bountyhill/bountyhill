# encoding: utf-8

# The Liability model.
#
# The Liability model records each individual liability for an account.
class Liability < ActiveRecord::Base
  belongs_to :account
  belongs_to :other_account, :class_name => "Account"
  belongs_to :reference, :polymorphic => true

  money :amount, :validate => false
  
  validates_presence_of :account, :other_account, :reference, :amount

  # Generate a pair of liabilities. The creditor is the user which will
  # receive the amount, the debitor is the user which will have to pay
  # the amount. 
  #
  # If the amount is not a Money object, it is assumed to be in cent.
  #
  # who pays and who receives is defined in the options hash, as follows:
  #
  #   # \a foo has to pay 1000 cents to \a bar because of \a reason
  #   Liability.generate 1000, foo => bar, :reason => reason
  #
  def self.generate(amount, options)
    debitor = options.keys.detect { |k| k.is_a?(User) }
    creditor = options[debitor]
    
    expect! creditor => User, debitor => User, amount => [Fixnum, Money]

    amount = Money.new(1000, Money.default_currency) if amount.is_a?(Fixnum)
    reference = options[:reference]
    
    transaction do
      creditor_account = creditor.account || creditor.create_account
      debitor_account = debitor.account || debitor.create_account

      creditor_account.liabilities.create! :other_account => debitor_account,
        :reference => reference, :amount => amount 

      debitor_account.liabilities.create! :other_account => creditor_account,
          :reference => reference, :amount => -amount
    end
  end
end
