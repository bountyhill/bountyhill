# encoding: UTF-8

module ApplicationController::Debugging
  def debug(key=nil, value=nil)
    @debug ||= []
    if key && value
      W key.to_s, value
      key = CGI.escapeHTML(key.to_s)
      value = CGI.escapeHTML(value.is_a?(Symbol) ? value.to_s : value.inspect)
      @debug << "<b>#{key}:</b><br /><code>#{value}</code>".html_safe
    end
    @debug
  end
end
