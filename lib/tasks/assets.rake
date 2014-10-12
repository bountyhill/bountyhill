# encoding: UTF-8

namespace :assets do
  desc "Rebuild assets"
  task :rebuild => %W(clean precompile remove_jquery)

  task :instance do
    ENV["INSTANCE"] = "deployment-web1"
  end
  
  task :clean => :instance
  task :precompile => :instance
  
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
end
