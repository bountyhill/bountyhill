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
  validates :identities,  :presence => true
  validates :message,     :presence => true, :length => { :maximum => 120 }
  
  validate :validate_identities
  
  #
  # All identities that allow a owner to share a quest
  # by sending tweets, posting on timeline, etc.
# TODO: enable sharing with all social identities...
#  IDENTITIES = %w(twitter facebook google linkedin xing)
  IDENTITIES = %w(twitter facebook linkedin xing)
  
  #
  # detect user's identities that allow sharing
  def init_identities
    Share::IDENTITIES.each do |identity|
      identities[identity] ||= owner && owner.identity?(identity.to_sym)
    end
  end
  
  #
  # triggers the posting of a share within
  # all bountyhill social networks
  def post_all
    return unless application
    
    Share::IDENTITIES.each{ |identity| "Identity::#{identity.camelize}".constantize.post(get_message, :object => quest) }
    self.shared_at = Time.now
    save!
  end
  
  #
  # triggers the posting of a share with the 
  # given identity and stores the time the
  # share was posted in the identities hash
  def post(identity)
    expect! identity => [Symbol]
    
    owner.identity(identity).post(get_message, :object => quest)
    owner.reward_for(quest, :share)
    
    identities[identity] = Time.now
    save!
  end

private 

  def get_message
    msg = message.gsub(/(^\s+)|(\s+$)/, "").gsub(/\s\s+/, " ")
    msg = quest.title if msg.blank?
    msg
  end

  def validate_identities
    # if we share the object within bounthill's social networks,
    # we do not require any user social networks to be present
    return if application

    # if we do not share the object within bounthill's social networks,
    # we do rewuire at least one network to share in to be choosen
    return if identities.keys.any?{ |identity| Share::IDENTITIES.include?(identity) }
    
    self.errors.add :base, I18n.t("share.errors.identities")
  end
  
end
