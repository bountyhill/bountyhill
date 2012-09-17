class Offer < ActiveRecord::Base
  include ActiveRecord::RandomID
  include ImageAttributes

  extend Forwardable
  delegate [:title, :bounty] => :quest
  
  # -- Associations ---------------------------------------------------
  
  belongs_to :quest
  serialize :serialized, Hash
  
  attr_accessible :location, :description, :image, :quest_id
  
  # -- Access control -------------------------------------------------
  
  # Offers are visible to both its owner and to the quest owner, but 
  # they can be written by its owner only.

  access_control do |user|
    if user
      joins(:quests).
      where("owner_id=? OR quests.owner_id=?", user.id, user.id)
    end
  end

  write_access_control :owner

  # -- scopes and filters ---------------------------------------------
  
  scope :own,       lambda { where(:owner_id => ActiveRecord::AccessControl.current_user) }
  scope :received,  lambda { 
    joins(:quest).where("quests.owner_id=?", ActiveRecord::AccessControl.current_user)
  }
  scope :with_criteria, joins(:quest).where("quests.number_of_criteria > 0")
  
  def self.filters
    %w(all own received with_criteria)
  end
  
  def self.filter_scope(name)
    return self if name.nil? || name == "all"
    
    expect! name => filters
    self.send(name)
  end
  
  # -- Validation -----------------------------------------------------

  validates_presence_of :quest
  validates_presence_of :description
  
  # Can make an offer on an active quest only.
  validate :validate_quest_is_active, :on => :create
  
  def validate_quest_is_active
    return if quest && quest.active?
    errors.add(:base, "quest is not active") 
  end

  # -- Attributes and accessors ---------------------------------------
  
  
  # -- Criteria -------------------------------------------------------
  
  NUMBER_OF_CRITERIA = Quest::NUMBER_OF_CRITERIA
  
  # returns the names of the criteria compliance attributes
  def self.criteria_compliances
    @criteria_compliances ||= 
      0.upto(NUMBER_OF_CRITERIA-1).map do |idx| 
        "criterium_compliance_#{idx}"
      end
  end
  
  # returns the names of the criteria_id attributes
  def self.criteria_ids
    @criteria_ids ||= 
      0.upto(NUMBER_OF_CRITERIA-1).map do |idx| 
        "criterium_id_#{idx}"
      end
  end
  
  serialized_attr *criteria_compliances, *criteria_ids
  attr_accessible *criteria_compliances, *criteria_ids

  validates_numericality_of *criteria_compliances,
    :only_integer => true,
    :allow_nil => true,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 10

  # returns an array of hashes a la
  #
  # [ 
  #   { 
  #     :criterium_id => 176257652,
  #     :title => "I am the first criterium", 
  #     :description => "And I tell more about the first criterium." 
  #     :compliance => (0..10)
  #   } 
  # ] 
  #
  # The title and description entries are read from the quest.
  # 
  # The description_id is a hash of the description title. It is used
  # to connect offer and quest criteria.
  def criteria
    r = []
    
    quest_criteria = quest.criteria.by(:criterium_id)
    
    offer_criteria = 0.upto(NUMBER_OF_CRITERIA-1).map do |idx|
      get_criterium idx
    end.compact.by(:criterium_id)
    
    criteria = quest_criteria.map do |criterium_id, quest_criterium|
      if offer_criterium = offer_criteria[criterium_id]
        quest_criterium = quest_criterium.merge(offer_criterium)
      end
      
      quest_criterium[:compliance] ||= 5
      quest_criterium
    end
  end

  private
  
  def get_criterium(idx)
    criterium_id = self.send(Offer.criteria_ids[idx])
    compliance = self.send(Offer.criteria_compliances[idx] || 5)

    return {} unless criterium_id
    
    {
      :criterium_id => criterium_id,
      :compliance => compliance
    }
  end

  def set_criterium(idx, uid, compliance)
    criterium_id_attr = Offer.criteria_ids[idx]
    criterium_compliance_attr = Offer.criteria_compliances[idx]
    self.send "#{criterium_id_attr}=", uid
    self.send "#{criterium_compliance_attr}=", compliance
  end
  
  # -- Compliance: The compliance value is the average of the individual
  #    compliances in all criteria. The compliance value is 50 if there 
  #    are no criteria.
   
  public
  
  def compliance
    if changed?
      calculate_compliance
    else
      read_attribute(:compliance)
    end
  end
  
  private
  
  before_save :save_compliance

  def save_compliance
    self.compliance = calculate_compliance
  end
  
  # calculate the compliance in % (an integer in the range of 0..100)
  def calculate_compliance
    criteria = self.criteria
    return 50 if criteria.blank?

    sum = criteria.inject(0) do |s, criterium|
      s + criterium[:compliance]
    end

    (sum * 100.0 / (criteria.length * 10)).round
  end

  public
  
  def image
    super || quest.image
  end
end
