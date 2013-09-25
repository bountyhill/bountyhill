class Development::MailInterceptor
  
  #
  # rewrites subject and to of all mails sent in developmment mode
  # see also sendgrid initializer where this interceptor is configured
  def self.delivering_email(message)
    message.from    = "admin@bountyhill.com"
    message.to      = "dev@bountyhill.com"
    message.subject = "#{message.to} #{message.subject}"
  end
end