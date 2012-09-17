namespace :assets do
  desc "Rebuild and commit assets"
  task :release => %W(instance clean clean_from_git precompile commit)

  task :instance do
    ENV["INSTANCE"] = "deployment-web1"
  end
  
  task :clean_from_git do
    system "git rm -r public/assets"
  end
  
  task :commit do
    sh "git add public/assets"
    
    sh "git commit -m 'Updated assets'"
  end
end