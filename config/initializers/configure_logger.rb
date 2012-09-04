class ActiveSupport::BufferedLogger
  def formatter=(formatter)
    @log.formatter = formatter
  end
end

class Formatter
  SEVERITY_TO_BOUNTYBASE   = {'DEBUG'=> :debug, 'INFO'=> :info, 'WARN'=> :warn, 'ERROR'=> :error, 'FATAL'=>:error, 'UNKNOWN'=>:warn}

  def call(severity, time, progname, msg)
    return if msg.index('Started GET "/assets/')

    severity = SEVERITY_TO_BOUNTYBASE[severity] || :warn
    Event.deliver :warn, Bountybase.logger, msg.strip
    nil
  end
end

::Event.severity = :debug
Rails.logger.formatter = Formatter.new
