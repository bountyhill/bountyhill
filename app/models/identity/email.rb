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
  EMAIL_ADDRESS_REGEX = /^([^@\s]+)@((?:[-a-z0-9]+\.)+(eu|ath.cx|co.uk|aero|arpa|asia|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|nato|net|org|pro|travel|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|fx|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw))$/i

  validates :name,      presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :password,  presence: true, length: { minimum: MIN_PASSWORD_LENGTH }
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
