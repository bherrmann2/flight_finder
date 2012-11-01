require "find"
require "ftools"
require "fileutils"

#
# 26 apr 2011 jwerwath    Original based on replacedir.rb
#
#
def niceexit(msg) 
  puts "ERRORS:\n" + msg
  exit
end

if (ARGV.length < 1)
  puts "All music files in a directory are converted to a tracklist      "
  puts "suitable for a torrent description.  The tracks are expected to be"
  puts "in <track#>-<title> format.                                       "
  puts "USAGE: ruby #{$0} <dir>"
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


file_count = 0

tracklist = Array.new
#For each file in dir #1 see if it exists in root dir #2
Find.find(dir) do |f|
  if (File.exists?(f) && !File.directory?(f))
    basename = File.basename(f)
    if (basename =~ /\.flac$/ || basename =~ /\.mp3$/)
      tracklist << basename.gsub(/\.\w+$/,'') 
    end
  end
end
puts tracklist.sort.join("\n")
