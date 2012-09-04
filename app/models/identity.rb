# stores a user's identity.
#
# An identity is needed to
# 
# - interact with a specific identity provider (e.g. an Identity::Twitter
#   object contains all information needed to post to twitter on a
#   user's behalf), and  
# - to verify a certain level of user identification (e.g. to post
#   or to reply to a quest a user must (probably) have an email
#   identity.
#
# There are specific subclasses:
#
# - Identity::Twitter
# - Identity::Email
#
class Identity < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user, :on => :save
  
  after_destroy :delete_user_if_deleted_last_identity
  
  serialize :options, Hash
  
  private
  
  def delete_user_if_deleted_last_identity
    return if user.identities.any? { |identity| identity.id != self.id }
    user.destroy
  end

  public
  
  # Creates an Identity object. This method chooses the right implementation
  # class, depending on the values passed in, instantiates and saves it, and 
  # builds a corresponding user object.
  #
  # The create method returns the newly built (and probably saved) object.
  #
  #   Identity.create { :email => "Whatever"}
  def self.create(attributes)
    if attributes[:email]
      klass = Identity::Email
    end

    expect! klass => Class
    
    transaction do
      klass.new(attributes).tap do |identity|
        next unless identity.save
        user = User.new 
        user.identities << identity
        user.save!
      end
    end
  end
end
