# encoding: UTF-8

# ApplicationController::XHRRedirection adds a redirect_to method, which responds
# "properly" to XHR requests.
module ApplicationController::XHRRedirection
  M = ApplicationController::XHRRedirection

  # This method works like ActionController::Redirecting#redirect_to for non
  # XHR requests. For XHR requests accepting JS or HTML it renders a proper 
  # JS redirection, using "window.location = <url>;"
  #
  # This allows to use redirection to GET actions in controllers regardless
  # of the request type (as long as it comes from a browser.)
  #
  # Note that this breaks code if the server wants to redirect a request to
  # an XHR action somewhere else...
  def redirect_to(*args)
    return super unless request.xhr?

    # Note: this code modifies the options hash **in place**. This is intended: 
    # if this method is called with 
    #
    #   redirect_to :controller => "x", :action => "y", :notice => "z"
    #
    # then we want to extract the :notice key and call url_for with just the 
    # :controller and :action keys.
    
    # Extract flash
    options = args.last.is_a?(Hash) ? args.last : {}
    if flash = options.delete(:flash)
      self.flash.each do |key, value|
        self.flash[key] = value
      end
    elsif notice = options.delete(:notice)
      self.flash[:notice] = notice
    end
    
    # determine redirection URL.
    js = "window.location = #{url_for(args.first).to_json};\n"
    
    respond_to do |format|
      format.html   { render :text => M.javascript_tag(js); }
      format.js     { render :text => js }
      format.any    { super }
    end
  end

  def self.javascript_tag(*args)
    javascript_helper.javascript_tag(*args)
  end
  
  def self.javascript_helper
    @javascript_helper ||= begin
      # Uuu! Magic! The next line builds a ruby object and extends it with
      # all helpers needed for javascript_tag to work. Reason: This makes 
      # XHRRedirection work with controllers that don't support JavaScriptHelper 
      # themselves.
      "".extend(ActionView::Helpers::TagHelper).extend(ActionView::Helpers::JavaScriptHelper)
    end
  end
end
