require "find"
require "ftools"
require "fileutils"

if (ARGV.length != 1)
  puts "USAGE: ruby #{$0} <root_dir>"
  puts " e.g.  ruby #{$0} c:\\tmp1"
  exit(0)
end

dir = ARGV[0]

#Check our input
[dir].each do |d|
  if (!File.exists?(d) || !File.directory?(d)) then
    puts "the following either does not exist or is not a directory: " + d
    exit(0)
  end
end


#For each file in dir #1 see if it exists in root dir #2
Find.find(dir) do |f|
  if (File.exists?(f) && File.directory?(f))
    if (f.to_s =~ /\.svn$/)
      FileUtils.rm_r(f)
      puts "[DELETED]" + f 
    end
  end
end
