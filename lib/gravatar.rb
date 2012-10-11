module Gravatar
  extend self
  
  def url(options)
    expect! options => { 
              :default => [ String, nil ], 
              :email => [ String, nil ]
            }
    
    gravatar_id = Digest::MD5::hexdigest(options[:email].to_s.downcase)
  
    # return gravatar URL; the "d=mm" option specifies the "mystery man",
    # see http://de.gravatar.com/site/implement/images
    CGI.build_url "https://gravatar.com/avatar/#{gravatar_id}.png", 
      :s => options[:size],
      :d => (options[:default] || "mm") 
  end
end
