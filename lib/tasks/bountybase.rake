namespace :bountybase do
  desc "Sync bountybase 'gem'"
  task :release => %W(push pull)
  
  task :push do
    sh "(cd vendor/bountybased; git push)"
  end

  task :pull do
    sh "(cd vendor/bountybase; git pull)"
    system "git commit -m 'Updated bountybase' vendor/bountybase"
  end
end