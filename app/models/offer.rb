class Offer < ActiveRecord::Base
  opinio_subjectum

  include ActiveRecord::RandomID
  include ImageAttributes

  with_metrics! "offers"

  extend Forwardable
  delegate [:bounty] => :quest
  
  STATES = %w(offered viewed withdrawn accepted rejected)
  
  # -- Associations ---------------------------------------------------
  
  belongs_to :quest
  serialize :serialized, Hash
  
  attr_accessible :title, :description, :images, :location, :quest_id, :quest, :state
  
  belongs_to :owner, :class_name => "User"
  validates  :owner, :presence => true
  
  # -- Access control -------------------------------------------------
  # Offers are visible to both its owner and to the quest owner, but 
  # they can be written by its owner only.

  access_control do |user|
    if user
      joins(:quest).
      where("offers.owner_id=? OR quests.owner_id=?", user.id, user.id)
    end
  end

  write_access_control :owner

  # -- scopes and filters ---------------------------------------------
  
  # relevant offers for a user: own or received
  scope :relevant_for,  lambda { |user|
    joins(:quest).
    where("quests.owner_id=? OR offers.owner_id=?", user, user) 
  }
  
  # -- Validation -----------------------------------------------------

  validates :quest,       :presence => true
  validates :title,       :presence => true, :length => { :maximum => 100 }
  validates :description, :presence => true, :length => { :maximum => 2400 }
  validates :state,       :presence => true, :inclusion => Offer::STATES
  
  # Can make an offer on an active quest only.
  validate :validate_quest_is_active, :on => :create
  
  def validate_quest_is_active
    return if quest && quest.active?
    errors.add(:base, "quest is not active") 
  end
  
  # -- Initial setup -------------------------------------------------------
  
  def initialize(attributes={})
    super

    # init criteria ids from quest if not provided by attributes hash, 
    # e.g. on initial setup of offer
    self.criteria.each_with_index do |criterium, idx|
      next if self.send("criterium_id_#{idx}").present?
      self.send("criterium_id_#{idx}=", criterium[:criterium_id])
    end
  end
    
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

  # returns the names of the criteria comment attributes
  def self.criteria_comments
    @criteria_comments ||= 
      0.upto(NUMBER_OF_CRITERIA-1).map do |idx| 
        "criterium_comment_#{idx}"
      end
  end
  
  serialized_attr *criteria_compliances, *criteria_ids, *criteria_comments
  attr_accessible *criteria_compliances, *criteria_ids, *criteria_comments

  validates_numericality_of *criteria_compliances,
    :only_integer => true,
    :allow_nil    => true,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to    => 10

  # returns an array of hashes a la
  #
  # [ 
  #   { 
  #     :criterium_id => 176257652,
  #     :title => "I am the first criterium", 
  #     :description => "And I tell more about the first criterium." 
  #     :comment => "I fullfil this criterum partially because of ..."
  #     :compliance => (0..100)
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
      if (offer_criterium = (offer_criteria[criterium_id] || offer_criteria[criterium_id.to_s]))
        quest_criterium = quest_criterium.merge(offer_criterium)
      end
      
      quest_criterium[:compliance] ||= 5
      quest_criterium
    end
  end

  private
  
  def get_criterium(idx)
    criterium_id  = self.send(Offer.criteria_ids[idx])
    compliance    = self.send(Offer.criteria_compliances[idx] || 5)
    comment       = self.send(Offer.criteria_comments[idx])
    
    return {} unless criterium_id
    
    {
      :criterium_id => criterium_id,
      :compliance   => compliance,
      :comment      => comment
    }
  end

  def set_criterium(idx, uid, compliance, comment=nil)
    self.send "#{Offer.criteria_ids[idx]}=",          uid
    self.send "#{Offer.criteria_compliances[idx]}=",  compliance
    self.send "#{Offer.criteria_comments[idx]}=",     comment
    get_criterium(idx)
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

    sum = criteria.inject(0) { |s, criterium| s + criterium[:compliance].to_i }
    (sum * 100.0 / (criteria.length * 10)).round
  end

  public
  
  def url
    Bountyhill::Application.url_for "/offers/#{self.id}"
  end

  # -- states ---------------------------------------------------------
  # An offer is active if the quest is still running, and it is not
  # decided upon.
  
  # The offer is not decided upon, and the quest is still active?
  def active?
    quest.active? && state.nil?
  end 

  def withdraw!
    raise ArgumentError, "Quest is no longer active" unless active?
    update_attributes! "state" => "withdrawn"
  end
  
  def accept!
    raise ArgumentError, "Quest is no longer active" unless active?
    update_attributes! "state" => "accepted"
  end
  
  def reject!
    raise ArgumentError, "Quest is no longer active" unless active?
    update_attributes! "state" => "rejected"
  end

  def withdrawn?
    state == "withdrawn"
  end
  
  def accepted?
    state == "accepted"
  end
  
  def rejected?
    state == "rejected"
  end

  # -- send out emails
  
  after_save :send_state_change_mail, :if => :state_changed?
  after_create :send_state_change_mail
  
  def send_state_change_mail
    mail = case state
    when "withdrawn"  then UserMailer.offer_withdrawn(self)
    when "accepted"   then UserMailer.offer_accepted(self)
    when "rejected"   then UserMailer.offer_rejected(self)
    when nil          then UserMailer.offer_received(self) # after creation
    end
    
    Deferred.mail mail
  end
  
  # returns an array of users connecting the quest with the sender
  # of this offer. The following users are excluded:
  # - the quest owner
  # - the offer offer
  # - the bountyhill admin user 
  def chain
    transaction do
      identities = quest.chain_to(owner).map do |screen_name|
        ::Identity::Twitter.find_or_create :screen_name => screen_name
      end

      identities.map(&:user) - [ quest.owner, owner, User.admin ]
    end
  end
end
