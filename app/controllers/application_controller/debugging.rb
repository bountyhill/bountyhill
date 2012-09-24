module ApplicationController::Debugging
  def debug(key=nil, value=nil)
    @debug ||= []
    if key && value
      key, value = CGI.escapeHTML(key), CGI.escapeHTML(value.inspect)
      @debug << "<b>#{key}:</b><br /><code>#{value}</code>".html_safe
    end
    @debug
  end
end
