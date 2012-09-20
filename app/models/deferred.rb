# Deferred runs methods asynchonously.
module Deferred
  def self.method_missing(sym, *args) #:nodoc:
    super unless instance_methods.include?(sym)

    queue(sym) << args
  end
  
  # return a queue with a specific name, which runs the Deferred#name action.
  def self.queue(name)
    @queues ||= {}
    @queues[name] ||= create_queue(name)
  end
  
  def self.create_queue(name)
    unless instance_methods.include?(name)
      raise ArgumentError, "Invalid Deferred action #{name.inspect}" 
    end
    
    GirlFriday::WorkQueue.new(name, :size => 1) do |args|
      Thread.send :sleep, 0.3

      instance = Object.new.extend(Deferred)
      instance.send name, *args
    end
  end

  # -- run a twitter request ------------------------------------------
  
  TWITTER_CONFIG = Bountybase.config.twitter_app
  
  def twitter(*args)
    oauth = args.extract_options!
    
    expect! oauth => {
      :oauth_token  => String,
      :oauth_secret => String
    }

    client = Twitter::Client.new(
      :oauth_token        => oauth[:oauth_token],
      :oauth_token_secret => oauth[:oauth_secret],
      :consumer_key       => TWITTER_CONFIG["consumer_key"],
      :consumer_secret    => TWITTER_CONFIG["consumer_secret"]
    )

    client.send *args
  end

  # -- deliver an email -----------------------------------------------
  
  def mail(mail)
    STDERR.puts "---- Sending email ------------------------\n#{mail}"
    mail.deliver
  end
end
