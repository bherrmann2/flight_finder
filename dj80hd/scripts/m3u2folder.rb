require "find"
require "ftools"
require "fileutils"

if (ARGV.length != 2)
  puts "USAGE: ruby m3u2folder <m3u_filename> <directory_to_copy_files>"
  puts " e.g.  ruby m3ufolder songs.m3u \c:tmp"
  exit(0)
end

m3u_file = ARGV[0]
dir = ARGV[1]

if (!File.exists?(m3u_file))
  puts (m3u_file + " does not exist")
  exit(0)
end 
if (File.exists?(dir) && !File.directory?(dir))
  puts ("The following is not a directory: " + dir)
  exit(0)
end

#get the contents of a file as an array of lines
lines = open(m3u_file) {|f| f.readlines()}
lines.uniq! #Remove Dups
files_to_move = []
lines.each do |l|
  f = l.chop
  if File.file? f then
    files_to_move << f
  else
    puts "WARNING!  This file does not exist and will not be copied: " + f
  end
end
puts files_to_move.length.to_s + " files to move..."
files_to_move.each do |f|
  #FIXME - catch this exception 
  begin
    FileUtils.copy(f,dir)
  rescue
    puts "WARNING! Copy for this file failed: " + f
  end
end
puts "DONE!"
#WHAT is the ruby one liner to filter this list and warn of the ones that
# dont exist.
#FileUtils.move(f,"g:\\2sort\\m4a")
#File.delete(f)

