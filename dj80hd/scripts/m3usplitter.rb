require 'rubygems'
require 'collections'
require "find"
require "ftools"
require "fileutils"

if (ARGV.length != 2)
  puts "USAGE: ruby #{$0} <m3u_filename> <max_size_new_m3u_in_meg>"
  puts " e.g.  ruby #{$0} songs.m3u 700"
  puts " would split songs.m3u into playlists that are no more than 700M"
  exit(0)
end

m3u_file = ARGV[0]
#FIXME - check this is an int
max_size_in_meg = ARGV[1]
max_size_in_bytes = max_size_in_meg.to_i * 1024 * 1024
if (!File.exists?(m3u_file))
  puts (m3u_file + " does not exist")
  exit(0)
end 
if not (m3u_file =~ /\.m3u$/)   
  puts (m3u_file + " does not end in '.m3u'")
  exit(0)
end 
#FIXME: File.dirname requires forward slashes ????
dir_of_m3u_file = File.dirname(m3u_file)
m3u_basename = File.basename(m3u_file)
puts "DIR: #{dir_of_m3u_file}"
m3u_absolute_filename = "" 

#get the contents of a file as an array of lines
lines = open(m3u_file) {|f| f.readlines()}
lines.uniq! #Remove Dups
lines.delete_if {|x| (x =~ /^#/) or (x =~ /^\s+$/) }

songs = SequencedHash.new


lines.each do |l|
  f = l.chop
  absolute_filename = File.expand_path(f,dir_of_m3u_file)
  if File.file? absolute_filename then
    #files_to_move << f
    puts "OK: #{absolute_filename} [" + File.size(absolute_filename).to_s + "]"
    songs[f] = File.size(absolute_filename)
  else
    puts "WARNING!  This file does not exist and will not be copied: " + absolute_filename
  end
end

#IF the sum of the files is less than the max leave it alone.
if (songs.values.inject(0){|sum,item| sum + item} <= max_size_in_bytes)
  puts "The total size of the playlist is less than the max. No splits created."
  exit 0
end

m3u_split_count = 1
m3u_current_size = 0
m3u_current_file = ""
#Create a m3u file in the same directory as the original
m3u_current_file = m3u_file.gsub(/\.m3u/,'_') + m3u_split_count.to_s + ".m3u"
m3u_split_count += 1

songs.keys.each do |f|
  #If this song size puts us past the maximum for this list, create a new one
  if (m3u_current_size + songs[f] > max_size_in_bytes)
    m3u_current_file = m3u_file.gsub(/\.m3u/,'_') + m3u_split_count.to_s + ".m3u"
    m3u_split_count += 1
    m3u_current_size = 0
  end
  File.open(m3u_current_file,"a") {|m3u| m3u.puts(f + "\n") }
  m3u_current_size = m3u_current_size + songs[f]
end
#puts files_to_move.length.to_s + " files to move..."
#files_to_move.each do |f|
#  #FIXME - catch this exception 
#  begin
#    FileUtils.copy(f,dir)
#  rescue
#    puts "WARNING! Copy for this file failed: " + f
#  end
#end
puts "DONE!"

