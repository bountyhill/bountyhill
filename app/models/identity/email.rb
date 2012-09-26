class Identity::Email < Identity
  # Fix Rails' polymorphic routes
  def self.model_name #:nodoc:
    Identity.model_name
  end

  after_create :send_confirmation_email
  
  def send_confirmation_email
    Deferred.mail UserMailer.confirm_email(user)
  end
  
  with_metrics! "accounts.email"
   
  attr_accessible :name, :email, :password, :password_confirmation
  has_secure_password
  
  # constant to use with name validation
  MAX_NAME_LENGTH     = 256

  # constant to use with password validation
  MIN_PASSWORD_LENGTH = 6

  # constant to use with email validation
  EMAIL_ADDRESS_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,6}$/i

  # validates :name,      presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :password, :length => { minimum: MIN_PASSWORD_LENGTH }, :on => :create
  validates :email,     presence: true, format: { with: EMAIL_ADDRESS_REGEX }, 
                                        uniqueness: { case_sensitive: false }

  def self.authenticate(email, password)
    identity = find_by_email(email)
    identity.authenticate(password) if identity
  end
  
  def avatar(options)
    expect! options => { :default => [ String, nil ]}
    
    gravatar_id = Digest::MD5::hexdigest(email.downcase)
    CGI.build_url "http://gravatar.com/avatar/#{gravatar_id}.png", 
      :s => options[:size],
      :d => options[:default]
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!(flag)
    Identity::Email.update_all({:confirmed_at => flag ? Time.now : nil}, :id => id)
    reload
  end
end
