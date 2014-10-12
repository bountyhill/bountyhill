# encoding: UTF-8

namespace :bountybase do
  desc "Sync bountybase 'gem'"
  task :release => %W(push pull commit)
  
  # sync development version
  task :push do
    sh "(cd vendor/bountybased; git pull; git push)"
  end

  # pull live version
  task :pull do
    sh "(cd vendor/bountybase; git pull)"
  end
  
  task :commit do
    system "git commit -m 'Updated bountybase' vendor/bountybase"
  end
end