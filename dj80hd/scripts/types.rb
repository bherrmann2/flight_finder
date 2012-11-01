require "mp3info"
require "find"
USAGE = "USAGE: ruby types.rb\nThis scripts prints all the extensions found underneath the current directory\n" 
types = Hash.new(0)
Find.find('.') do |f|
  if (File.file?(f))
    types[File.extname(f)] += 1
  end
end

types.each do |k,v|
 puts k + ":" + v.to_s 
end

