# encoding: utf-8

class Quest < ActiveRecord::Base
  opinio_subjectum

  include ActiveRecord::RandomID
  include ImageAttributes

  with_metrics! "quests"

  # If no duration is set when starting a quest this is the duration
  # to use instead.
  
  DURATIONS_IN_DAYS         = [ 3, 7, 14, 21 ]
  DEFAULT_DURATION_IN_DAYS  = 7
  
  # -- Access control -------------------------------------------------

  belongs_to :owner, :class_name => "User"
  validates  :owner, :presence => true
  
  has_many  :forwards
  has_many  :forwarders, :through => :forwards, :source => :sender
  
  # Quests are visible by the owner and when set to visibility public.
  access_control :visibility
  write_access_control :owner

  # -- scopes and filters ---------------------------------------------

  # Each status matches the name of a scope, as defined below. (Except
  # for all, probably?)
  STATUSES = [ 
    :all,
    :active,
    :with_offers,
    :pending,
    :expired
  ]
  
  # active: started and no yet expired
  scope :active,    lambda { where("quests.started_at IS NOT NULL AND quests.expires_at > ?", Time.now) }

  # pending: not yet started
  scope :pending,    lambda { where("quests.started_at IS NULL") }

  # with_offers: quests that received offers
  scope :with_offers,  lambda { include(:offers).where("offers.id") }

  # expired: well, expired
  scope :expired,   lambda { where("quests.expires_at <= ?", Time.now) }

  # This is what the current_user sees on the /quests list
  scope :for_current_user, lambda { 
    if !ActiveRecord.current_user
      # active. 
      where("quests.expires_at > ?", Time.now) 
    else
      # active or pending. Note: a non admin user would only see her own
      # pending quests. An admin user sees all pending quests.
      where("quests.started_at IS NULL OR quests.expires_at > ?", Time.now) 
    end
  }
  
  # Find a quest, even if it does not belong to the current_user, but to
  # User.draft. We'll need this when a user enters a quest before she is
  # registered: in that case the quest will be attached to User.draft.
  #
  # Note that this code is a bit insecure: one could try to guess a quest
  # id of a quest which is still a draft and then take over this quest. 
  # Lucky for us we have randomized quest ids.
  def self.draft(id)
    ActiveRecord.as(User.admin) do |previous_user| 
      quest = Quest.find(id)

      # Verify that this quest is actually a draft or a quest which belongs
      # the the current_user (which is available here as previous_user). 
      if !previous_user || !previous_user.owns?(quest)
        if !quest.owner.draft?
          raise ActiveRecord::RecordNotFound, "#{quest.uid} is not a draft" 
        elsif quest.created_at < Time.now - 10.minutes
          raise ActiveRecord::RecordNotFound, "#{quest.uid} is too old" 
        end
      end

      quest
    end
  end

  # -- CATEGORIES -----------------------------------------------------
  
  CATEGORIES = %w(misc jobs estate service lost missing crime electronics sports entertainment cars boats)
  
  scope :with_category, lambda { |category|
    expect! category => CATEGORIES
    where("quests.category = ?", category)
  }
  
  def category_t
    I18n.t(category, :scope => "quest.categories")
  end
  
  # -- Validations ----------------------------------------------------

  validates :category,    :presence => true, :inclusion => CATEGORIES
  validates :title,       :presence => true, :length => { :maximum => 100 }
  validates :description, :presence => true, :length => { :maximum => 2400 }
  
  DEFAULT_BOUNTY = 100 # 1 EUR
  money :bounty

  serialize :serialized, Hash
  serialized_attr :duration_in_days
  
  attr_accessible :title, :description, :images, :bounty, :location, :duration_in_days, :category

  # -- Cancellation ---------------------------------------------------

  # reason for cancellation
  CANCELLATIONS = %w(bountyhill_success other_success no_longer_needed)

  serialized_attr :cancellation, :cancellation_reason
  attr_accessible :cancellation, :cancellation_reason
  
    
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
  
  after_create :reward_creator
  
  def reward_creator
    owner.reward_for(self)
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
    return if started?

    duration_in_days = (self.duration_in_days || DEFAULT_DURATION_IN_DAYS).to_i
    if duration_in_days > 0
      expires_at = (Date.today + duration_in_days + 1).to_time - 1
    end

    self.visibility = "public"
    self.started_at = Time.now
    self.expires_at = expires_at

    # clear out cancellation reasons from potential previous cancellation
    self.cancellation = nil
    self.cancellation_reason = nil

    save!
    owner.reward_for(self, :start)
  end

  def cancel!(attributes = {})
    self.attributes = attributes
    self.visibility = nil
    self.expires_at = Time.now
    
    save!
    owner.reward_for(self, :stop)
  end
  
  # -- quest statistics -----------------------------------------------
  
  # returns an array of top quests visible to all users.
  #
  # Parameters:
  
  def self.top_quests(options = {})
    expect! options => { 
      :limit => [Fixnum, nil] 
    }
    
    # We show active quests only. They are available to all users anyways
    # so there is no point in running with less then admin clearance. 
    ActiveRecord.as(User.admin) do
      Quest.active.all(:limit => options[:limit], :order => "bounty_in_cents DESC")
    end
  end
  
  # return a Hash of stats for the current_user; e.g.
  #
  # { :all => 12, :pending => 10, ... }
  def self.stats
    STATUSES.inject({}) do |hash, scope_name|
      scope = scope_name == :all ? self : self.send(scope_name)
      hash.update scope_name => scope.count
    end 
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
  
  def bounty_height
    return 0 unless self.active?
    return 5 if bounty_in_cents.zero?
    
    case (bounty_in_cents/100).to_s.size
    when 1 then 15
    when 2 then 30
    when 3 then 60
    when 4 then 90
    else        100
    end
  end
  
end
