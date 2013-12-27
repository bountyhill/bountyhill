# encoding: UTF-8

settings = {
  :port           => "25",
  :authentication => :plain,
}

if Rails.env.development?
  
  ActionMailer::Base.smtp_settings = settings.merge(
    :address    => "smtp.googlemail.com",
    :user_name  => "admin@bountyhill.com",
    :password   => "sweet1972",
    :domain     => "bountyhill.com")

  # sent emails to internal users only!
  ActionMailer::Base.default_url_options[:host] = "localhost:3000"
  Mail.register_interceptor(Development::MailInterceptor)
  
else
  
  ActionMailer::Base.smtp_settings = settings.merge(
    :address    => "smtp.sendgrid.net",
    :user_name  => ENV['SENDGRID_USERNAME'],
    :password   => ENV['SENDGRID_PASSWORD'],
    :domain     => ENV['SENDGRID_DOMAIN'])
    
end
