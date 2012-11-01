require "find"
require "ftools"
require "fileutils"
require "mp3_utils"

#
# 22 jan 2009 jwerwath    Original based on mergedir_zeb.
#
include Mp3Utils

if (ARGV.length < 2)
  puts "Prints all the mp3 files in target_dir that already exist in source_dir"
  puts "USAGE: ruby #{$0} <source_dir> <target_dir>"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2"
  exit(0)
end

source = Hash.new
target = Hash.new
dir1 = ARGV[0]
dir2 = ARGV[1]
source['dir'] = dir1
source['hash'] = Hash.new
target['dir'] = dir2
target['hash'] = Hash.new


#Check our input
[dir1,dir2].each do |d|
  if (!File.exists?(d) || !File.directory?(d)) then
    puts "the following either does not exist or is not a directory: " + d
    exit(0)
  end
end


#Build up our data structure.
[source,target].each do |o|
  dir = o['dir']
  hash = o['hash']
  Find.find(dir) do |f|
    if (File.exists?(f) && !File.directory?(f))
      if ((f =~ /\.mp3$/i) || (f =~ /\.mp4/i) || (f =~ /\.flac/i))
        k = mp3hash(f)
        hash[k] = f.to_s
        puts "#{k}:#{f}"
      end 
    end
  end #Find
end 

source['hash'].keys.each_pair do |k,orig|
  dup = target['hash'][k] 
  if (dup)
    puts "#{dup} is a DUP of #{orig}"
  end
end
