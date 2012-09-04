#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Bountyhill::Application.load_tasks

#
# This makes sure that the default rake task runs the "test:units" task also.
task :default => "test:units"
