# encoding: UTF-8

if(Rails.env.production?)

  ActionMailer::Base.smtp_settings = {
    # :address        => 'smtp.sendgrid.net',
    # :port           => '587',
    # :authentication => :plain,
    # :user_name      => ENV['SENDGRID_USERNAME'],
    # :password       => ENV['SENDGRID_PASSWORD'],
    # :domain         => 'heroku.com',
    :port           => ENV['MAILGUN_SMTP_PORT'],
    :address        => ENV['MAILGUN_SMTP_SERVER'],
    :user_name      => ENV['MAILGUN_SMTP_LOGIN'],
    :password       => ENV['MAILGUN_SMTP_PASSWORD'],
    :domain         => 'bountyhill-staging.com',
    :authentication => :plain,
  }
  ActionMailer::Base.delivery_method = :smtp
  
else

  ActionMailer::Base.smtp_settings = {
    :address        => "smtp.googlemail.com",
    :port           => "25",
    :authentication => :plain,
    :user_name      => "admin@bountyhill.com",
    :password       => "sweet1972",
    :domain         => "bountyhill.com"
  }

  # sent emails to internal users only!
  ActionMailer::Base.default_url_options[:host] = "localhost:3000"
  Mail.register_interceptor(Development::MailInterceptor)
  
end