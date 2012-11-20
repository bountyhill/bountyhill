#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# show rake invocation
def headline
  s = "rake #{ARGV.join(" ")}"
  count = (130 - s.length) / 2
  STDERR.puts "\n#{">" * count} rake #{ARGV.join(" ")} #{"<" * count}\n\n"
end
headline

# load application tasks
require File.expand_path('../config/application', __FILE__)
Bountyhill::Application.load_tasks

# This makes sure that the default rake task runs the "test:units" task also.
task :default => "test:units"
