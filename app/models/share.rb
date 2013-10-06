# encoding: UTF-8

class Share < ActiveRecord::Base
  belongs_to :quest
  belongs_to :owner, :class_name => "User"

  extend Forwardable
  delegate [:title, :url, :bounty] => :quest
  
  #
  # holds the identities the owner wants to share with
  #
  # initially the hash contains all identities the owner can share with (as keys)
  # and the information if the owner has a valid identity to share with (as values)
  #
  # once a share is created, the identities hash contains all identities the owner wants 
  # to share with (as keys) and the time the system did actually performed the sharing (as values)
  serialize :identities, Hash
  
  attr_accessible :quest, :quest_id, :owner, :owner_id, :identities, :message
  
  validates :quest,       :presence => true
  validates :owner,       :presence => true
  validates :identities,  :presence => true
  validates :message,     :presence => true, :length => { :maximum => 140 }
  
  validate :validate_identities
  
  #
  # All identities that allow a owner to share a quest
  # by sending tweets, posting on timeline, etc.
  IDENTITIES = %w(twitter facebook)

  #
  # detect user's identities that allow sharing
  def initialize(attributes={}, options={})
    # initializing from the share form
    return super if attributes.delete(:title)

    # initializing for the shares form
    super
    
    Share::IDENTITIES.each do |identity|
      identities[identity] ||= owner && owner.identity?(identity.to_sym)
    end
  end
  
  #
  # triggers the actual posting of a share
  # with the given identity and stores the time the
  # share was posted in the identities hash
  def post(identity)
    expect! identity => [Symbol]
    
    msg = message.gsub(/(^\s+)|(\s+$)/, "").gsub(/\s\s+/, " ")
    msg = title if msg.blank?
    
    owner.identity(identity).update_status "#{msg} #{url}"
    owner.reward_for(self.quest, :share)
    
    identities[identity] = Time.now
    save!
  end

private 

  def validate_identities
    return if identities.keys.any?{ |identity| Share::IDENTITIES.include?(identity) }
    
    self.errors.add :base, I18n.t("share.errors.identities")
  end
  
end
