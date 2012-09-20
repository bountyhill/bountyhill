MailQ = GirlFriday::WorkQueue.new(:mailq, :size => 1) do |mail|
  STDERR.puts "---- Sending email ------------------------\n#{mail}"
  mail.deliver
end
