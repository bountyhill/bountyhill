namespace :bountyhill do
  task :setup => :environment do
    Bountybase::Metrics.in_background = false
    Deferred.in_background = false
  end

  desc "Delete all content"
  task :reset => :setup do
    User.all.each(&:destroy)
  end
end
