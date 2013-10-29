# encoding: UTF-8

class Quest < ActiveRecord::Base
  opinio_subjectum

  include ActiveRecord::RandomID
  include ImageAttributes

  with_metrics! "quests"

  # If no duration is set when starting a quest this is the duration
  # to use instead.
  
  DURATIONS_IN_DAYS         = [ 1, 3, 7, 14, 21, 28 ]
  DEFAULT_DURATION_IN_DAYS  = 14
  
  # -- Access control -------------------------------------------------

  belongs_to :owner, :class_name => "User"
  validates  :owner, :presence => true

  has_one   :location, :as => :stationary
  accepts_nested_attributes_for :location, :allow_destroy => true
  
  has_many  :forwards
  has_many  :forwarders, :through => :forwards, :source => :sender
  
  # Quests are visible by the owner and when set to visibility public and
  # quests should be visible to offerer as well
  #
  # Note: mind to add 'readonly(false)' to ensure fetched objects are not readonly
  #       see http://stackoverflow.com/questions/5004459/rails-3-scoped-finds-giving-activerecordreadonlyrecord
  #
  access_control do |user|
    if user
      joins("LEFT JOIN offers ON offers.quest_id=quests.id").
      where("quests.visibility=? OR offers.owner_id=? OR quests.owner_id=?", "public", user.id, user.id).readonly(false)
    else
      where("quests.visibility=?", "public")
    end
  end
  
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
        elsif quest.created_at < Time.now - 1.hour
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
  
  scope :nearby, lambda { |location, radius|
    expect! location  => String
    expect! radius    => Location::RADIUS
    
    # set radius to maximum
    # TODO: there has to be a better way, 
    # e.g. # see http://stackoverflow.com/questions/6695752/using-a-rails-scope-as-a-proxy-for-the-scope-of-a-related-object    
    return if Location.unlimited?(radius)
    
    where("quests.id IN (?)", Location.near(location, radius, :units => :km, :select => "locations.stationary_id", :order => :distance).
      where("locations.stationary_type = ?", 'Quest').map(&:stationary_id))
#      :select => "quests.id",
#      :joins => "LEFT OUTER JOIN `locations` ON `locations`.`stationary_id` = `quests`.`id` AND `locations`.`stationary_type` = 'Quest'"))
  }

  # -- Validations ----------------------------------------------------

  validates :category,    :presence => true, :inclusion => CATEGORIES
  validates :title,       :presence => true, :length => { :maximum => 100 }
  validates :description, :presence => true, :length => { :maximum => 2400 }
  
  DEFAULT_BOUNTY = 100 # 1 EUR
  money :bounty

  serialize :serialized, Hash
  serialized_attr :duration_in_days
  
  attr_accessor :restrict_location
   
  attr_accessible :title, :description, :images, :bounty, :duration_in_days, :category, :restrict_location, :location_attributes

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

  # TODO: not needed?
  # def set_criterium(idx, title, description = nil)
  #   title_attr = Quest.criteria_titles[idx]
  #   description_attr = Quest.criteria_descriptions[idx]
  #   
  #   self.send "#{title_attr}=", title
  #   self.send "#{description_attr}=", description
  # end

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
    return if owner.draft?
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
  has_many :offers, :order => "created_at DESC", :dependent => :destroy do
    def for_user(user)
      all(:conditions => ["offers.owner_id = ? OR offers.state != ?", user, 'new'])
    end
  end
  
  # -- Quest status ---------------------------------------------------
  
  def active?
    started? && !expired?
  end
  
  def expired?
    expires_at && expires_at < Time.now
  end
  
  def started?
    started_at.present?
  end
  
  def start!
    return if active?

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

    # save quest and reward user
    save!
    owner.reward_for(self, :start)
    
    self
  end

  def stop!(attributes = {})
    return if !active?
    
    self.attributes = attributes
    self.visibility = nil
    self.expires_at = Time.now
    
    # save quest and reward user
    save!
    owner.reward_for(self, :stop)
    
    self
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
  
    chain.map(&:attributes).pluck("identifier")
  end

  # -- Pseudo attributes ----------------------------------------------
  
  def location_attributes=(attributes={})
    if location.present?
      location.attributes = attributes 
    else
      build_location(attributes)
    end
  end
  
  def compliance
    offers.all.map(&:compliance).sort.last
  end
  
  def url
    Bountyhill::Application.url_for "/q/#{self.id}"
  end
  
  def restrict_location?
    restrict_location.present?
  end
  
end
