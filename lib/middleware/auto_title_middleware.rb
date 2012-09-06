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
      doc = Nokogiri.HTML(body)
      if h1 = doc.css("h1").first
        "<title>#{prefix} | #{h1.text}</title>"
      else
        "<title>#{prefix}</title>"
      end
    end

    [status, headers, [body]]
  end
end
