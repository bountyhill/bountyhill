class Quest < ActiveRecord::Base
  include ActiveRecord::RandomID
  
  # Quests are visible by the owner and when set to visibility public.
  access_control :visibility
  
  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2400 }
  
  serialize :image, Hash
  
  money :bounty
  
  attr_accessible :title, :description, :bounty, :image

  def ui_mode
    if readonly?      then "show"
    elsif new_record? then "create" 
    else "edit"
    end
  end
end
