# encoding: UTF-8

class Share < ActiveRecord::Base
  belongs_to :quest
  belongs_to :owner, :class_name => "User"

  extend Forwardable
  delegate [:url, :bounty] => :quest
  
  #
  # holds the identities the owner wants to share with
  #
  # initially the hash contains all identities the owner can share with (as keys)
  # and the information if the owner has a valid identity to share with (as values)
  #
  # once a share is created, the identities hash contains all identities the owner wants 
  # to share with (as keys) and the time the system did actually performed the sharing (as values)
  serialize :identities, Hash
  
  attr_accessor :title
  attr_accessible :quest, :quest_id, :owner, :owner_id, :identities, :message, :title, :application
  
  validates :quest,       :presence => true
  validates :owner,       :presence => true
  validates :identities,  :presence => true, :unless => :application
  validates :message,     :presence => true, :length => { :maximum => 120 }
  
  validate :validate_identities
  
  #
  # All identities that allow a owner to share a quest
  # by sending tweets, posting on timeline, etc.
  IDENTITIES = %w(twitter facebook google linkedin xing)
  
  #
  # detect user's identities that allow sharing
  def init_identities
    Share::IDENTITIES.each do |i|
      next unless owner
      next unless (identity = owner.identity(i.to_sym)).present?
      identities[i] ||= identity.api_accessible?
    end
  end
  
  
  #
  # triggers the posting of a share with the 
  # given identity and stores the time the
  # share was posted in the identities hash
  def post!(identity)
    expect! identity => [Symbol]
    
    # triggers the posting of a share within bountyhill's social network
    "Identity::#{identity.to_s.camelize}".constantize.post(get_message, :object => quest)
    
    # triggers the posting of a share within user's social network
    owner.identity(identity).post(get_message, :object => quest)
    identities.update(identity.to_s => Time.now)
    save!
  end

private 

  def get_message
    msg = message.gsub(/(^\s+)|(\s+$)/, "").gsub(/\s\s+/, " ")
    msg = quest.title if msg.blank?
    msg
  end

  def validate_identities
    return if application
    return if shared_at.present?

    # if we do not share the object within bounthill's social networks,
    # we do require at least one network to share in to be choosen
    return if identities.keys.any?{ |identity| Share::IDENTITIES.include?(identity) }
    
    self.errors.add :base, I18n.t("share.errors.identities")
  end
  
end
