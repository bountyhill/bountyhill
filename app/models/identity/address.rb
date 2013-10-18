# encoding: UTF-8

class Identity::Address < Identity
  include Identity::PolymorphicRouting
  
  with_metrics! "accounts.address"

  serialized_attr :company, :address1, :address2, :city, :zipcode, :country, :phone
  attr_accessible :company, :address1, :address2, :city, :zipcode, :country, :phone
 
  # -- validation -----------------------------------------------------
  validates :address1, :city, :zipcode, :country, :presence => true
  validates :company, :phone, :presence => true, :if => :commercial?
    
  #
  # the whole postal address
  def postal
    [:company, :address1, :address2, :city, :zipcode, :country].map do |attribute| 
      part = self.send(attribute)
      part.strip unless part.blank?
    end.compact
  end
  
private
  
  def commercial?
    user && user.commercial?
  end
end
