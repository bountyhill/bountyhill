class Quest < ActiveRecord::Base
  include ActiveRecord::RandomID

  belongs_to :owner, :class_name => "User"
  validates_presence_of :owner
  
  # Quests are visible by the owner and when set to visibility public.
  access_control :visibility
  write_access_control :owner
  
  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2400 }
  
  serialize :image, Hash
  
  money :bounty
  
  attr_accessible :title, :description, :bounty, :image, :image_url, :location

  serialize :serialized, Hash
  
  def ui_mode
    if readonly?      then "show"
    elsif new_record? then "create" 
    else "edit"
    end
  end

  NUMBER_OF_CRITERIA = 6
  
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

    return nil unless title
    
    {
      :title => title,
      :description => self.send("criterium_description_#{idx}"),
      :criterium_id => title.crc32
    }
  end
  
  public
  
  # returns an array of hashes a la
  #
  # [ 
  #   { 
  #     :criterium_id => 176257652,
  #     :title => "I am the first criterium", 
  #     :description => "And I tell more about the first criterium." 
  #   } 
  # ] 
  # 
  # The description_id is a hash of the description title. It is used
  # to connect offer and quest criteria.
  def criteria
    0.upto(NUMBER_OF_CRITERIA-1).map do |idx|
      get_criterium idx
    end.compact
  end
  
  # Offers to the quest are ordered by their compliance value.
  has_many :offers, :order => "compliance DESC"
  
  # Answer the quest. This method is built so that the attributes
  # can be filled in from a HTML form without much hassle.
  def offer!(offer)
    return :offer_has_already_ended if expired?
    
    offer.calculate_compliance
  end
  
  IMAGE_SIZES = {
    "thumbnail" => "90x90", 
    "fullsize"  => "640x480", 
    "original"  => nil
  }
  
  def image_url=(url)
    image = {}
    
    IMAGE_SIZES.each do |name, size|
      if size 
        width, height = size.split(/\D+/).map(&:to_i)
        size_url = "http://imgio.heroku.com/jpg/fill/#{size}/#{url}"
      end
      
      image[name] = {
        "url"     => size_url || url,
        "mime"    => "image/jpeg",
        "width"   => width,
        "height"  => height
      }
    end
    
    self.image = image
  end
  
  def original_image_url
    original = image && image["original"]
    url = original && original["url"]
    
    # If the original URL already points to an imgio instance; i.e. if it looks like
    # this: "http://imgio.heroku.com/jpg/fill/90x90/http://some.where/123456.jpg",
    # the following line extracts the original URL from the imgio URL.
    url.gsub(/.*\d\/http/, "http") if url
  end
  
  def expired?
    expires_at && expires_at < Time.now
  end

  def published?
    started_at.present?
  end
  
  def publish!
    self.visibility = "public"
    self.started_at = Time.now

    save!
  end
  
  def number_of_tweets
    cached :time_to_live => 60 do
      Bountybase::Graph.number_of_tweets self.id
    end
  end

  def longest_chain
    cached :time_to_live => 60 do
      Bountybase::Graph.longest_chain self.id
    end
  end

  def compliance
    offers.all.map(&:compliance).sort.last
  end
  
  # def number_of_offers
  #   rand(5)
  # end
  # 
  # 
  # def ends_at
  #   Time.now + rand(1000000)
  # end
  # 
  # def location
  #   "Hamburg, Germany"
  # end
end
