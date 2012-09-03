# 
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'

  version = Time.now.to_s
  rdoc.title = "Bountyhill #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('app/**/*.rb')
end


