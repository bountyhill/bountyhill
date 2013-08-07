# encoding: UTF-8

Dir.glob(__FILE__.gsub(/\.rb$/, "/**/*.rb")).sort.each do |file|
  require file
end