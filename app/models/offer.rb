class Offer < ActiveRecord::Base
  include ActiveRecord::RandomID

  # Offers are visible to the owner and the owner of the quest.
  access_control do |user|
    if user
      joins(:quests).
      where("owner_id=? OR quests.owner_id=?", user.id, user.id)
    end
  end

  write_access_control :owner
    
  belongs_to :quest

  # The quest's criteria. Each criteria consists of a single piece of 
  # text, and a random id number. Each answer will hold a compliance
  # value between 0 and 1 and the same random id number.  
  def criteria
    # ...
  end
  
  def calculate_compliance
    quest_criteria = quest.criteria.by(&:uid)
    
    if quest_criteria.empty?
      self.compliance = 1
      return
    end
    
    criteria = self.criteria.by(&:uid)

    self.compliance = quest_criteria.
      map { |quest_criterium| criteria[quest_criterium.uid] }.
      map { |criterium| criterium ? criterium.compliance : 0 }.
      average
  end
end
