require "find"
require "ftools"
require "fileutils"
require "song"
require "songlist"

#FIXME - Not done.
#This file will take a folder (like 4Hess and either locate or copy the music
#file to a library base directory (how to determine directory structure of library?) then create an m3u file of the folder that points to each track in the 
#library

def clean_pathname(pathname)
	#FIXME THIS IS WINDOWS ONLY
	#	if (system.os.name == "nt")
    return pathname.gsub(/\//,"\\")
    # else
    #return pathname.gsub(/\\/,'/')
    #end
end

if (ARGV.length != 3)
  #FIXME - Is there a cool ruby way to automatically wrap this text for 80 col ?
  puts "For use when you have a folder of music that you know is duplicated in a larger \nlibrary.  This script takes the one folder and looks for all the files in the root of the libarary.\nThen in creates a m3u of what it finds in the libarary.\n"
  puts "USAGE: ruby #{$0} <m3u_filename> <folder_directory> <root_directory to search for files>"
  puts " e.g.  ruby #{$0} songs.m3u c:\\tmp c:\\my_library"
  exit(0)
end

m3u_file = ARGV[0]
folder_dir = ARGV[1]
library_dir = ARGV[2]

#if (File.exists?(m3u_file))
#  puts ("m3u file '" + m3u_file + "' already exists.")
#  exit(0)
#end

[folder_dir,library_dir].each do |d|
  if (File.exists?(d) && !File.directory?(d))
    puts("The following is not a directory: " + d)
    exit(0)
  elsif (!File.exists?(d))
    puts("The following is directory does not exist: " + d)
    exit(0)
  end
end
files_in_m3u = []
music_in_folder = Songlist.new
music_in_library = Songlist.new
music_in_folder.load_from_dir(folder_dir)
music_in_library.load_from_dir(library_dir)

#Generate a SongList for music_files_in_library and music_files_in_folder
#Foreach music_files_in_folder
#  if it is contained in the music_files_in_library add that path to m3u
#  else
#    copy the song to the library and add the path to m3u
#
puts music_in_folder.as_string

music_in_folder.songs.each do |s|
  matched_song = music_in_library.find_song(s)
  if (matched_song != nil) 
    puts "FOUND  " + matched_song.basename
    files_in_m3u << matched_song.filename
  else
    File.copy(s.filename,library_dir)
    #FIXME - Preserve a directory structure here ?
    if (File.exists?(library_dir + "/" + s.basename))
      puts "COPIED: " + s.basename
    else
      puts "ERROR COPY: " + s.basename
    end
  end
end

Songlist.array2m3u(files_in_m3u,m3u_file)
if (File.exists?(m3u_file)) then
  puts "SUCCESS: " + m3u_file + " CREATED !"
else
  print "ERROR CREATING M3U FILE " + m3u_file
end
