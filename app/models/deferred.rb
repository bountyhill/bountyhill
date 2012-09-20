module Deferred
  # -- implementations: all methods below can be run deferredly 
  # via Deferred.name; e.g. Deferred.twitter runs Deferred#twitter
  # in a background thread.
  def self.method_missing(sym, *args)
    super unless instance_methods.include?(sym)

    queue(name) << args
  end
  
  def self.queue(name)
    @queues ||= {}
    @queues[name] ||= GirlFriday::WorkQueue.new(name, :size => 1) do |*args|
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
  
  def mail(email)
    expect! email => Mail::Message
    
    STDERR.puts "---- Sending email ------------------------\n#{mail}"
    mail.deliver
  end
end
