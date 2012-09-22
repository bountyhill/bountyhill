module RequestedForms
  def requested_forms
    case params[:req]
    when "email"    then %w(by_email)
    when "twitter"  then %w(by_twitter)
    else            %w(by_email by_twitter)
    end
  end

  def self.included(klass)
    klass.helper_method :requested_forms
  end
end
