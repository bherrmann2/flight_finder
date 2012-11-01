require "find"
require "ftools"
require "fileutils"

def clean_pathname(pathname)
	#FIXME THIS IS WINDOWS ONLY
	#	if (system.os.name == "nt")
    return pathname.gsub(/\//,"\\")
    # else
    #return pathname.gsub(/\\/,'/')
    #end
end
def is_music_file(filename)
	return false unless File.file?(filename)
  return true if (filename =~ /\.mp3$/i) 
  return true if (filename =~ /\.mp4$/i) 
  return true if (filename =~ /\.wav$/i) 
  return true if (filename =~ /\.flac$/i) 
  return true if (filename =~ /\.wma$/i) 
  return true if (filename =~ /\.m4a$/i) 
  return true if (filename =~ /\.m4p$/i) 
  return false
end

if (ARGV.length != 2)
  puts "USAGE: ruby folder2m3u <m3u_filename> <directory>"
  puts " e.g.  ruby folder2m3u songs.m3u c:\\tmp"
  exit(0)
end

m3u_file = ARGV[0]
dir = ARGV[1]

if (File.exists?(m3u_file))
  puts ("m3u file '" + m3u_file + "' already exists.")
  exit(0)
end 
if (File.exists?(dir) && !File.directory?(dir))
  puts("The following is not a directory: " + dir)
  exit(0)
elsif (!File.exists?(dir))
  puts("The following is directory does not exist: " + dir)
  exit(0)
end

music_files = []
Find.find(dir) do |f|
  if (is_music_file(f) && !File.directory?(f))
    music_files << clean_pathname(f)
  end
end

file_content = music_files.join("\n")

begin
  open(m3u_file,"w").write(file_content)
rescue
  puts "ERROR - There was a problem writing to #{m3u_file}"
end

