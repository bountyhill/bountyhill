# encoding: UTF-8

class Offer < ActiveRecord::Base
  opinio_subjectum

  include ActiveRecord::RandomID
  include ImageAttributes

  with_metrics! "offers"

  extend Forwardable
  delegate [:bounty] => :quest
  
  STATES = %w(new active withdrawn accepted rejected)
  
  # -- Associations ---------------------------------------------------
  belongs_to :quest

  belongs_to :owner, :class_name => "User"
  validates  :owner, :presence => true

  serialize :serialized, Hash
  
  attr_accessible :title, :description, :images, :location, :quest_id, :quest, :state  
  
  # -- Access control -------------------------------------------------
  # Offers are visible to both its owner and to the quest owner, but 
  # they can be written by its owner only.
  #
  # Note: mind to add 'readonly(false)' to ensure fetched objects are not readonly
  #       see http://stackoverflow.com/questions/5004459/rails-3-scoped-finds-giving-activerecordreadonlyrecord
  #
  access_control do |user|
    if user
      joins(:quest).
      where("offers.owner_id=? OR (quests.owner_id=? AND offers.state != 'new')", user.id, user.id).readonly(false)
    end
  end

  write_access_control :owner

  # -- scopes and filters ---------------------------------------------
  
  scope :with_state, lambda { |state|
    expect! state => STATES
    where("offers.state = ?", state)
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
  
  def initialize(attributes={}, options={})
    super
    return unless quest
    
    # init criteria ids from quest if not provided by attributes hash, 
    # e.g. on initial setup of offer
    quest.criteria.each_with_index do |criterium, idx|
      next if self.send("criterium_id_#{idx}").present?
      self.send("criterium_id_#{idx}=", criterium[:criterium_id])
    end
  end
    
  # -- WITHDRAWALS ---------------------------------------------------

  # reason for withdrawle
  WITHDRAWALS = %w(offer_invalid other_reason)

  serialized_attr :withdrawal, :withdrawal_reason
  attr_accessible :withdrawal, :withdrawal_reason
  
  # -- REJECTIONS ---------------------------------------------------

  # reason for rejection
  REJECTIONS = %w(offer_missmatch quest_invalid other_reason)

  serialized_attr :rejection, :rejection_reason
  attr_accessible :rejection, :rejection_reason

  # -- ACCEPTANCES ---------------------------------------------------

  # reason for acceptance
  ACCEPTANCES = %w(offer_match other_reason)

  serialized_attr :acceptance, :acceptance_reason
  attr_accessible :acceptance, :acceptance_reason
  
  
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

  # TODO: not needed?
  # def set_criterium(idx, uid, compliance, comment=nil)
  #   self.send "#{Offer.criteria_ids[idx]}=",          uid
  #   self.send "#{Offer.criteria_compliances[idx]}=",  compliance
  #   self.send "#{Offer.criteria_comments[idx]}=",     comment
  #   get_criterium(idx)
  # end
  
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
  
  after_create :reward_creator
  
  def reward_creator
    owner.reward_for(self)
  end

  public
  
  def url
    Bountyhill::Application.url_for "/offers/#{self.id}"
  end

  #
  # set viewed_at at first time view of non-owner
  def viewed!(user = ActiveRecord::AccessControl.current_user)
    return if viewed_at.present? || user.owns?(self)
    ActiveRecord::AccessControl.as(owner) do
      update_attribute(:viewed_at, Time.now)
    end
  end

  # -- states and state manipulations --------------------------------------------------
  
  def new?
    state == "new"
  end
  
  def active?
    # The offer is not decided upon, and the quest is still active
    state == "active" && quest.active?
  end
  
  def outdated?
    # The offer is not decided upon, but the quest is no longer active
    state == "active" && !quest.active?
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

  def activate!
    raise RuntimeError, "Offer: #{self.inspect} is alredy active" unless new?

    update_attributes! "state" => "active"
    owner.reward_for(self, :activate)
    self
  end

  def withdraw!(attributes={})
    raise RuntimeError, "Offer: #{self.inspect} is no longer active" unless active?

    update_attributes! attributes.slice(:withdrawal, :withdrawal_reason).merge(:state => "withdrawn")
    owner.reward_for(self, :withdraw)
    self
  end
  
  def accept!(attributes={})
    raise RuntimeError, "Offer: #{self.inspect} is no longer active" unless active?
    raise RuntimeError, "User: #{ActiveRecord::AccessControl.current_user.inspect} has to own quest: #{quest.inspect} to accept this offer: #{self.inspect}!" unless ActiveRecord::AccessControl.current_user.owns?(quest)
    
    ActiveRecord::AccessControl.as(owner) do
      update_attributes! attributes.slice(:acceptance, :acceptance_reason).merge(:state => "accepted")
    end

    quest.owner.reward_for(self, :accept)
    self
  end
  
  def reject!(attributes={})
    raise RuntimeError, "Offer: #{self.inspect} is no longer active" unless active?
    raise RuntimeError, "User: #{ActiveRecord::AccessControl.current_user.inspect} has to own quest: #{quest.inspect} to reject this offer: #{self.inspect}!" unless ActiveRecord::AccessControl.current_user.owns?(quest)
    
    ActiveRecord::AccessControl.as(owner) do
      update_attributes! attributes.slice(:rejection, :rejection_reason).merge(:state => "rejected")
    end
    
    quest.owner.reward_for(self, :reject)
    self
  end
  

  # -- send out emails
  
  after_save :send_state_change_mail, :if => :state_changed?
  after_create :send_state_change_mail
  
  def send_state_change_mail
    mail = case state
      when "withdrawn"  then UserMailer.offer_withdrawn(self)
      when "accepted"   then UserMailer.offer_accepted(self)
      when "rejected"   then UserMailer.offer_rejected(self)
      when "active"     then UserMailer.offer_received(self) # after activation
      else # no mail, e.g on state 'new'
      end
    
    Deferred.mail(mail) if mail
  end
  
  # returns an array of users connecting the quest with the sender
  # of this offer. The following users are excluded:
  # - the quest owner
  # - the offer offer
  # - the bountyhill admin user 
  def chain
    transaction do
      identities = quest.chain_to(owner).map do |identifier|
        ::Identity::Twitter.find_or_create(identifier)
      end

      identities.map(&:user) - [ quest.owner, owner, User.admin ]
    end
  end
end
