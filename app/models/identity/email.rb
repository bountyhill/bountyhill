# encoding: UTF-8

class Identity::Email < Identity
  include Identity::PolymorphicRouting
  
  attr_accessor :password_new, :password_new_confirmation

  with_metrics! "accounts.email"
  after_create :send_confirmation_email
   
  attr_accessible :user, :name, :email, :password, :password_confirmation, :newsletter_subscription
  has_secure_password
  
  # -- validation -----------------------------------------------------
  
  # constant to use with password validation
  MIN_PASSWORD_LENGTH = 6

  # constant to use with email validation
  EMAIL_ADDRESS_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,6}$/i

  validates :email,     :presence => true, :format =>  { :with => EMAIL_ADDRESS_REGEX }, :uniqueness => { :case_sensitive => false }
  validates :password,  :length => { :minimum => MIN_PASSWORD_LENGTH }

  # -- authenticate ---------------------------------------------------
  
  def self.authenticate(email, password)
    identity = find_by_email(email)
    identity.authenticate(password) if identity
  end

  # -- methods --------------------------------------------------------
  
  def confirmed?
    confirmed_at.present?
  end

  def confirm!(flag)
    Identity::Email.update_all({:confirmed_at => flag ? Time.now : nil}, :id => id)
    reload
  end

  
private

  def send_confirmation_email
    Deferred.mail UserMailer.confirm_email(user)
  end
  
end
