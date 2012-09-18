namespace :assets do
  desc "Rebuild and commit assets"
  task :release => %W(clean clean_from_git precompile remove_jquery commit)

  task :clean => :instance
  task :precompile => :instance
  
  task :instance do
    ENV["INSTANCE"] ||= "deployment-web1"
  end
  
  task :clean_from_git do
    system "git rm -r public/assets"
  end

  task :remove_jquery do 
    W "Remove jquery files from public/assets"
    digest = "[0-9a-f]" * 32

    patterns = [
      "jquery.js", 
      "jquery-ui.js"
    ]

    patterns = patterns.
      map { |pattern| [ pattern, pattern.sub(/\./, ".min.") ] }.flatten

    patterns = patterns.
      map { |pattern| [ pattern, pattern.gsub(/\.js$/, "-#{digest}.js") ] }.flatten

    patterns = patterns.
      map { |pattern| [ pattern, "#{pattern}.gz" ] }.flatten

    files = patterns.inject([]) do |ary, pattern|
      ary.concat Dir.glob("public/assets/#{pattern}")
    end

    files.each do |file|
      puts "rm #{file}"
      begin
        File.unlink(file)
      rescue
        puts $!
      end
    end
  end
  
  task :commit do
    sh "git add public/assets"
    
    sh "git commit -m 'Updated assets'"
  end
end
