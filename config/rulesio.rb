__END__

# this file goes into config/rulesio.rb

token 'lSh1jGpk5XwzIwXMR5Au1A'    # default channel (for user-centric events)
middleware :users                 # automatically generate events about user activity
middleware :exceptions do         # automatically generate events for exceptions
  token 'zg05oC2NBd-0btPSQMOwDg'  # separate channel for error-centric events
end

disable_sending_events if Rails.env.test?
# disable_sending_events if Rails.env.development?
