namespace :assets do
  desc "Rebuild and commit assets"
  task :prerelease => %W(clean precompile remove_jquery custom_compress)
  task :release => %W(clean_from_git prerelease commit)

  task :instance do
    ENV["INSTANCE"] = "deployment-web1"
  end
  
  task :clean => :instance
  task :precompile => :instance
  
  task :clean_from_git do
    system "git rm -rf public/assets"
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

  task :custom_compress do
    css_files = Dir.glob("public/assets/application*.css")
    js_files = Dir.glob("public/assets/application*.js")
    files = css_files + js_files

    old_sizes = files.inject({}) do |hash, file|
      hash.update file => File.size(file)

      file = file + ".gz"
      hash.update file => File.size(file)
    end
    
    yuicompressor = "java -jar data/yuicompressor-2.4.7.jar"
    sh "#{yuicompressor} --type css -o '.css$:.css.min' #{css_files.join(" ")}" unless css_files.empty?
    sh "#{yuicompressor} --type js -o '.js$:.js.min' #{js_files.join(" ")}" unless js_files.empty?
    
    files.each do |file|
      File.rename "#{file}.min", file
      sh "cat #{file} | gzip -9 > #{file}.gz"
    end
    
    files.each do |file|
      W "#{file}: #{old_sizes[file]} -> #{File.size(file)}"

      file = file + ".gz"
      W "#{file}: #{old_sizes[file]} -> #{File.size(file)}"
    end
  end
  
  task :commit do
    sh "git add public/assets"
    
    sh "git commit -m 'Updated assets'"
  end
end
