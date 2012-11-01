require "find"
require "ftools"

#
# 03 APR 2010 - Handle output files.

def music_file?(f)
  if (File.file?(f))
    return ((f =~ /\.mp3$/) || (f =~ /\.flac$/) || (f =~ /\.wav$/) || (f =~ /\.wma$/) || (f =~ /\.m4a/) || (f =~ /\.mp4/) || (f =~ /\.ogg/))
  end
  return false
end



if (ARGV.length == 0)
  puts "USAGE: ruby #{$0} <file_or_dir_1> <file_or_dir_2> ... <file_or_dir_n>"
  puts "  If the last file does not exist, use it as output.  Otherwise print"
  puts "  to STDOUT. "                                                        
  exit                                                                        
end

dbfile = nil
last_param = ARGV[-1]
param_count = ARGV.size
puts "last_parm=" + last_param
if (!File.exists?(last_param)) 
  param_count = param_count - 1
  dbfile = last_param
  puts last_param + " does not exist so I am writing output here."
else
  puts last_param + " exists so I think it is a parameter."
end
puts "WRITING OUTPUT TO " + ((dbfile != nil) ? dbfile : "STDOUT")


#Make our output
out = ""
ARGV[0,param_count].each do |x|
  if (File.file?(x))
    open(x) {|f| out = out + f.read}
    out = out + "\n"
  elsif (File.directory?(x))
    Find.find(x) {|f| out = out + f + " [" + (File.size(f).to_i/1000).to_s + "K]\n" unless (!music_file?(f))}
  else
     puts "ERROR!!! NOT A FILE OR DIRECTORY: " + x
  end
end

#Write it where we want it
if (dbfile != nil)
  open(dbfile,'w') do |o|
    o << out
  end
else
  puts out
end



