# encoding: UTF-8

module I18n::I18nExtensions
  def as(locale)
    old_locale = I18n.locale
    I18n.locale = locale.to_s[0, 2]
    yield
  ensure
    I18n.locale = old_locale
  end
  
  def as_default
    as(default_locale) { yield }
  end
  
end

I18n.extend I18n::I18nExtensions
