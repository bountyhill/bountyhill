class Identity::Email < Identity
  def self.model_name
    Identity.model_name
  end
   
  attr_accessible :name, :email, :password, :password_confirmation
  has_secure_password
  
  MAX_NAME_LENGTH     = 256
  MIN_PASSWORD_LENGTH = 6
  EMAIL_ADDRESS_REGEX = /^([^@\s]+)@((?:[-a-z0-9]+\.)+(eu|ath.cx|co.uk|aero|arpa|asia|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|nato|net|org|pro|travel|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|fx|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw))$/i

  before_save :create_remember_token

  validates :name,      presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :password,  presence: true, length: { minimum: MIN_PASSWORD_LENGTH }
  validates :email,     presence: true, format: { with: EMAIL_ADDRESS_REGEX }, uniqueness: { case_sensitive: false }

  
  private

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
end
