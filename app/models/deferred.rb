# Deferred runs methods asynchonously.
module Deferred

  def self.in_background?
    @in_background
  end

  def self.in_background=(in_background)
    @in_background = in_background
  end
  
  def self.in_background(flag, &block)
    old, @in_background = @in_background, flag
    yield
  ensure
    @in_background = old
  end
  
  self.in_background = true
  
  def self.method_missing(sym, *args) #:nodoc:
    super unless instance_methods.include?(sym)

    if in_background?
      queue(sym) << args
    else
      instance.send sym, *args
    end
  end
  
  def self.instance
    Object.new.extend(self)
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
      Thread.send :sleep, 0.2
      instance.send name, *args
    end
  end

  # -- run a twitter request ------------------------------------------
  
  # does a Twitter API call. The parameters include a oauth options
  # hash with all required oauth entries.
  def twitter(*args)
    oauth = args.extract_options!
    
    expect! oauth => {
      :oauth_token  => String,
      :oauth_token_secret => String, 
      :consumer_key => String,
      :consumer_secret => String
    }

    client = Twitter::Client.new(oauth)
    client.send *args
  end

  # -- deliver an email -----------------------------------------------
  
  def mail(mail)
    STDERR.puts "---- Sending email ------------------------\n#{mail}"
    mail.deliver
  end
end
