class Quest < ActiveRecord::Base
  include ActiveRecord::RandomID

  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2400 }
  
  attr_accessible :title, :description
  
  money :bounty
  validates_numericality_of :bounty_in_cents, :greater_than_or_equal_to => 0
  
  # Attributes
  # returns the bounty in ""
  def bounty
    bounty_in_cents * 0.01
  end

  def bounty=(bounty)
    self.bounty_in_cents = bounty * 100
  end
end
