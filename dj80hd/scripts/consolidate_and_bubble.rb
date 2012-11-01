require "mp3info"
require "find"
require "ftools"
USAGE = "USAGE: ruby consolidate_and_bubble.rb <source_directory> <target_directory>\nThis script 'bubbles' up all files under the source directory and copies them to the target_directory.  Duplicates are ignored."

def is_mp3_file?(filename)
	return (File.file?(filename) && (filename =~ /\.mp3$/i))
end

#FIXME - What is the ruby cool way to do this ?
def mp3s_in_dir(dirname)
  i = 0
  Find.find(dirname) do |f|
    if (is_mp3_file?(f)) then
      i = i + 1
    end
  end
  return i
end

if (ARGV.length != 2) then
  puts USAGE
  exit(0)
end

source_dir = ARGV[0]
target_dir = ARGV[1]

[source_dir,target_dir].each do |d|
  if (!File.directory?(d)) then
    puts "ERROR: " + d.to_s + " is not a valid diretory"
    exit(0);
  end
end
warnings = []
#Get a list of all the files in the directory...
Find.find(source_dir) do |f|
  if (is_mp3_file?(f))
    begin
      target_file = target_dir + "/" + File.basename(f)
      if (File.exists?(target_file)) then
        if (File.size(target_file) == File.size(f)) then
          warn =  "THIS ALREDY EXISTS: " + target_file
	  puts warn
	  warnings << warn 
        else
          target_file = target_dir + "/" + File.basename(f,".mp3") + "_1.mp3"
	  #FIXME - how to break/next/continue in ruby
          File.copy(f,target_file + "_1")
	  puts "COPIED: " + target_file
        end
      else
        File.copy(f,target_file)
	puts "COPIED: " + target_file
      end
    rescue
      warn = "COULD NOT COPY: #{f}" + $!
      warnings << warn
      puts warn
    end
  end
end

puts warnings.to_s

