class Quest < ActiveRecord::Base
  include ActiveRecord::RandomID

  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2400 }
  
  attr_accessible :title, :description, :bounty
  
  money :bounty
  
  belongs_to :user

  # received offers
  # has_many :received_hints, :class_name => "Hint"
end
