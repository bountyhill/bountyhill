# encoding: UTF-8

if Rails.env.development?
  
module I18n
  def self.html_error_message(exception, locale, key, options)
    if exception.is_a?(MissingTranslation)
      key = exception.keys.join('.')
      %(<span style="color: orange"><b>translation missing:</b> #{key}</span>).html_safe
    elsif exception.is_a?(Exception)
      raise exception
    else
      throw :exception, exception
    end
  end
end

I18n.exception_handler = :html_error_message

end
