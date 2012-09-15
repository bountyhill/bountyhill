class PrettyHTMLMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    status, headers, response = *@app.call(env)

    if headers["Content-Type"] !~ /\btext\/html\b/
      return [status, headers, response]
    end
    
    # Collect the document body.
    body = ""
    response.each { |part| body.concat part }

    doc = Nokogiri.HTML(body)
    body = doc.to_xhtml(indent:2)

    [status, headers, [body]]
  end
end
