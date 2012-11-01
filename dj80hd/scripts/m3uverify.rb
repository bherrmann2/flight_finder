require "find"
require "ftools"
require "fileutils"
require "song"
require "songlist"

#FIXME - There is probably some slick ruby way of lazy instantiation
#library_songlist = nil
#def get_library_songlist()
#  if library_songlist == nil
#    library_songlist = Songlist.new
#  end
#  return library_songlist
#end
#
# NOT DONE

USAGE = "USAGE: ruby m3uverify <m3u_filename> <examine|repair> [library root dir]\ne.g.  ruby m3uverify songs.m3u examine\ne.g.  ruby m3uverify songs.m3u repair c:\\tmp\\mymp3lib"
if (ARGV.length < 2)
  puts USAGE
  exit(0)
end

m3u_file = ARGV[0]
command = ARGV[1]
libdir = ARGV[2]

if (!File.exists?(m3u_file)||File.directory?(m3u_file))
  puts (m3u_file + " does not exist")
  exit(0)
end 
if (command != "examine" && command != "repair")
  puts ("The following is not a valid command: " + command)
  exit(0)
end
if (command == "repair" && libdir == nil           )
  puts ("You must specify a root directory for your library")
  puts USAGE
  exit(0)
end
if (command == "repair" && !File.directory?(libdir))
  puts ("The following is not a valid directory: " + libdir)
  exit(0)
end
library_songlist = nil
songs = Songlist.new
warnings = ""
#get the contents of a file as an array of lines
lines = open(m3u_file) {|f| f.readlines()}
lines.each do |l|
  f = l.strip
  if (Song.music_file?(f)) then
    s = Song.new(f)
    if (songs.include?(s)) then 
      warnings = warnings + "WARNING: THE FOLLOWING IS A DUP: " + f + "\n"
    else
      songs.append(s)
    end
  else
    # If we are just examining the m3u we will print this warning
    if (command == "examine")
      warnings = warnings +  "WARNING: THE FOLLOWING DOES NOT EXIST OR IS NOT A MUSIC FILE: " + f + "\n"

    #REPAIR - if the file does not exist try to find it.
    elsif (!File.exists?(f))
      if (library_songlist == nil)
        library_songlist = Songlist.new
	library_songlist.load_from_dir(libdir)
      end
      basename = File.basename(f)
      s = library_songlist.find_basename(basename)
      if (s != nil)                                        
        puts "the following was added from the library: " + basename
	songs.append(s)
      else
        #filesize_matches = library_songlist.find_filesize(File.size(f))
        #filesize_matches.each do |matching_song| 
        #  warnings = warnings + "NOTE: this file is also " + matching_song.filesize + "bytes: " + matching_song.basename
        #end
        warnings = warnings +  "WARNING: THE FOLLOWING DOES NOT EXIST: " + basename + "\n"
      end
    else
      warnings = warnings +  "WARNING: THE FOLLOWING IS NOT A MUSIC FILE: " + f + "\n"
    end
  end
end

if (command == "repair")
  songs.as_m3u(m3u_file)
  if (File.exists?(m3u_file)) then
    puts "SUCCESS: " + m3u_file + " CREATED !"
  else
    print "ERROR CREATING M3U FILE " + m3u_file
  end
end
if (warnings.length > 1)
  puts "WARNINGS\n--------\n" + warnings 
else
  puts "OK."
end
