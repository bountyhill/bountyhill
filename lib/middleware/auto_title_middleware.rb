# encoding: UTF-8

class AutoTitleMiddleware
  attr_reader :prefix
  
  def initialize(app, options = {})
    @app = app

    options = options.inject({}) { |hash, (k, v)| hash.update k.to_sym => v }

    @prefix = options[:prefix]
  end
  
  def call(env)
    status, headers, response = *@app.call(env)

    if headers["Content-Type"] !~ /\btext\/html\b/
      return [status, headers, response]
    end

    # Collect the document body.
    body = ""
    response.each { |part| body.concat part }

    # ..and replace the title placeholder.
    body.gsub!("<title></title>") do 
      title = extract_title(body)
      title = title ? "#{prefix} | #{title}" : prefix
      title = "[#{I18n.locale}] #{title}" if Rails.env.development?
      
      "<title>#{title}</title>"
    end
    
    [status, headers, [body]]
  end

  def extract_title(body)
    doc = Nokogiri.HTML(body)
    
    if h1 = doc.css("h1").first
      h1.text
    elsif h2 = doc.css("h2").first
      h2.text
    end
  end
end
