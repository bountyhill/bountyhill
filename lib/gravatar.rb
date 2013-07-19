module Gravatar
  extend self
  
  def url(email, options={})
    expect! email => [ String, nil ]
    expect! options => {
      :default  => [ String, nil ],
      :size     => [ Integer, nil ]
    }
    
    gravatar_id = Digest::MD5::hexdigest(email.to_s.downcase)
  
    # return gravatar URL; the "d=mm" option specifies the "mystery man",
    # see http://de.gravatar.com/site/implement/images
    CGI.build_url "https://gravatar.com/avatar/#{gravatar_id}.png", 
      :s => (options[:size]    || 64),
      :d => (options[:default] || "mm") 
  end
end
