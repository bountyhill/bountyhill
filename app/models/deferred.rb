# encoding: UTF-8

require "girl_friday"

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
  
  self.in_background = !Rails.env.test?
  
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
    raise(ArgumentError, "Invalid Deferred action #{name.inspect}") unless instance_methods.include?(name)
    
    GirlFriday::WorkQueue.new(name, :size => 1) do |args|
      begin
        W "Deferred.#{name}" unless Rails.env.test?
        Thread.send :sleep, 0.2
        instance.send name, *args
      rescue StandardError
        W "#{$!} in processing Deferred.#{name}; from\n\t" + $!.backtrace[0..4].join("\n\t")
        raise
      end
    end
  end

  # -- run a facebook request ------------------------------------------
  
  def facebook(*args)
    W "TRY facebook", *args                      unless Rails.env.test?

    oauth = args.extract_options!
    expect! oauth => {
      :oauth_token      => String,
      :oauth_expires_at => Time,
    }
    
    client = Koala::Facebook::API.new(oauth[:oauth_token])
    client.put_connections(*args)                 unless Rails.env.development?
    W "OK facebook", *args                        unless Rails.env.test?
  end

  # -- run a google+ request ------------------------------------------
  
  def google(*args)
    W "TRY google+", *args                      unless Rails.env.test?

    oauth = args.extract_options!
    expect! oauth => {
      :oauth_token        => String,
      :oauth_token_secret => String,
      :consumer_key       => String,
      :consumer_secret    => String
    }

    # TODO: leverage google+ client here....
    
    W "OK google+", *args                        unless Rails.env.test?
  end

  # -- run a linkedin request ------------------------------------------
  
  def linkedin(*args)
    W "TRY linkedin", *args                      unless Rails.env.test?

    oauth = args.extract_options!
    expect! oauth => {
      :oauth_token        => String,
      :oauth_token_secret => String,
      :consumer_key       => String,
      :consumer_secret    => String
    }

    client = LinkedIn::Client.new(oauth[:consumer_key], oauth[:consumer_secret])
    client.authorize_from_access(oauth[:oauth_token], oauth[:oauth_token_secret])    
    client.send(*args)                            unless Rails.env.development?
    
    W "OK linkedin", *args                        unless Rails.env.test?
  end

  # -- run a xing request ------------------------------------------
  
  def xing(*args)
    W "TRY xing", *args                           unless Rails.env.test?

    oauth = args.extract_options!

    client = Xing::Client.new(
      :consumer_key       => oauth[:consumer_key],
      :consumer_secret    => oauth[:consumer_secret],
      :oauth_token        => oauth[:oauth_token],
      :oauth_token_secret => oauth[:oauth_token_secret]
    )
    client.send(*args)                            unless Rails.env.development?
    
    W "OK xing", *args                            unless Rails.env.test?
  end

  # -- run a twitter request ------------------------------------------
  
  # does a Twitter API call. The parameters include a oauth options
  # hash with all required oauth entries.
  def twitter(*args)
    W "TRY twitter", *args                        unless Rails.env.test?

    oauth = args.extract_options!
    expect! oauth => {
      :oauth_token        => String,
      :oauth_token_secret => String,
      :consumer_key       => String,
      :consumer_secret    => String
    }

    client = Twitter::Client.new(oauth)
    client.send(*args)                            unless Rails.env.development?
    W "OK twitter", *args                         unless Rails.env.test?
  end

  # -- deliver an email -----------------------------------------------
  
  def mail(email)
    W "TRY email to #{email.to}", email.subject   unless Rails.env.test?
    email.deliver                                 unless Rails.env.development?
    W "OK email"                                  unless Rails.env.test?
  end
end
