# encoding: utf-8

class Quest < ActiveRecord::Base
  opinio_subjectum

  include ActiveRecord::RandomID
  include ImageAttributes

  with_metrics! "quests"

  # If no duration is set when starting a quest this is the duration
  # to use instead.
  
  DEFAULT_DURATION_IN_DAYS = 7
  
  # -- Access control -------------------------------------------------

  belongs_to :owner, :class_name => "User"
  validates  :owner, presence: true
  
  # Quests are visible by the owner and when set to visibility public.
  access_control :visibility
  write_access_control :owner

  # -- scopes and filters ---------------------------------------------

  # prepared: not yet started
  scope :prepared,  lambda { where("quests.started_at IS NULL") }

  # active: started and no yet expired
  scope :active,    lambda { where("quests.started_at IS NOT NULL AND quests.expires_at > ?", Time.now) }

  # expired: well, expired
  scope :expired,   lambda { where("quests.expires_at <= ?", Time.now) }
  
  # Find a quest, even if it does not belong to the current_user, but to
  # User.draft. We'll need this when a user enters a quest before she is
  # registered: in that case the quest will be attached to User.draft.
  def self.draft(id)
    ActiveRecord.as(User.admin) do |previous_user| 
      quest = Quest.find(id)

      W "quest.owner", quest.owner
      W "previous_user", previous_user
      
      if quest.owner != previous_user 
        if !quest.owner.draft?
          raise ActiveRecord::RecordNotFound, "#{quest.uid} is not a draft" 
        elsif quest.created_at < Time.now - 10.minutes
          raise ActiveRecord::RecordNotFound, "#{quest.uid} is too old" 
        end
      end

      quest
    end
  end
  
  # -- Validations ----------------------------------------------------
  
  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2400 }
  
  money :bounty

  serialize :serialized, Hash
  serialized_attr :duration_in_days
  
  attr_accessible :title, :description, :bounty, :location, :duration_in_days
  
  # -- Criteria -------------------------------------------------------
  
  NUMBER_OF_CRITERIA = 10
  
  # returns the names of the criteria title attributes
  def self.criteria_titles
    @criteria_titles ||= 
      0.upto(NUMBER_OF_CRITERIA-1).map do |idx| 
        "criterium_#{idx}"
      end
  end

  # returns the names of the criteria description attributes
  def self.criteria_descriptions
    @criteria_descriptions ||= 
      0.upto(NUMBER_OF_CRITERIA-1).map do |idx| 
        "criterium_description_#{idx}"
      end
  end
  
  serialized_attr *criteria_titles, *criteria_descriptions
  attr_accessible *criteria_titles, *criteria_descriptions

  private
  
  def set_criterium(idx, title, description = nil)
    title_attr = Quest.criteria_titles[idx]
    description_attr = Quest.criteria_descriptions[idx]
    
    self.send "#{title_attr}=", title
    self.send "#{description_attr}=", description
  end

  def get_criterium(idx)
    title = self.send Quest.criteria_titles[idx]
    description = self.send Quest.criteria_descriptions[idx]

    return nil unless title.present?
    
    {
      :title => title,
      :description => self.send("criterium_description_#{idx}"),
      :criterium_id => title.crc32
    }
  end
  
  before_save :update_number_of_criteria
  
  def update_number_of_criteria
    self.number_of_criteria = criteria.count
  end
  
  public
  
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
    0.upto(NUMBER_OF_CRITERIA-1).map do |idx|
      get_criterium idx
    end.compact
  end
  
  # -- Offers ---------------------------------------------------------
  
  # Offers to the quest are ordered by their compliance value.
  has_many :offers, :order => "compliance DESC", :dependent => :destroy
  
  # Answer the quest. This method is built so that the attributes
  # can be filled in from a HTML form without much hassle.
  def offer!(offer)
    return :offer_has_already_ended if expired?
    
    offer.calculate_compliance
  end
  
  # -- Quest status ---------------------------------------------------
  
  def active?
    started? and !expired?
  end
  
  def expired?
    expires_at && expires_at < Time.now
  end

  def started?
    started_at.present?
  end
  
  def started?
    started_at.present?
  end
  
  def start!
    unless started?
      Bountybase.reward owner, :points => 20
    end

    duration_in_days = (self.duration_in_days || DEFAULT_DURATION_IN_DAYS).to_i
    if duration_in_days > 0
      expires_at = (Date.today + duration_in_days + 1).to_time - 1
    end

    self.visibility = "public"
    self.started_at = Time.now
    self.expires_at = expires_at

    save!
  end

  def cancel!
    self.visibility = nil
    self.expires_at = Time.now
    save!
  end
  
  # -- Quest stats ----------------------------------------------------

  def number_of_tweets
    Bountybase.cached [ User.first, :number_of_tweets ], :ttl => 60 do
      Bountybase::Graph.propagation self.id
    end
  end

  # returns an array of twitter user names that follow the quest from
  # the original tweet to the passed in user. The user is not included
  # in the chain; the original account, if it is the "@bountyhill" 
  # or the owner's account, is.
  #
  # Note that this method can be slow. One should consider caching it
  # on the quest and the user.
  def chain_to(user)
    return [] unless twitter = user && user.identity(:twitter)
    return [] unless chain = Bountybase::Graph.chain(self.id, twitter.user_id)
  
    chain.map(&:attributes).pluck("screen_name")
  end

  # -- Pseudo attributes ----------------------------------------------
  
  attr :message, true
  attr :tweet, true
  attr_accessible :message, :tweet

  def compliance
    offers.all.map(&:compliance).sort.last
  end
  
  def url
    Bountyhill::Application.url_for "/q/#{self.id}"
  end
end
