class Quest < ActiveRecord::Base
  include ActiveRecord::RandomID

  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2400 }
  
  serialize :image, Hash
  
  money :bounty
  
  belongs_to :user
  attr_accessible :title, :description, :bounty, :image

  def ui_mode
    if readonly?      then "show"
    elsif new_record? then "create" 
    else "edit"
    end
  end
end
