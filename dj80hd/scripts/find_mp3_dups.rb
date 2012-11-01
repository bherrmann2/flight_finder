require "rubygems"
require "mp3info"
require "find"
require "ftools"
require "fileutils"

# THIS IS NOT DONE !!!
#
# Check input
if (ARGV.length != 1 || ARGV[0] == "-h" || ARGV[0] == "--help" ||!File.directory?(ARGV[0]))
  puts "Finds all the mp3 files in a given root directory\nwith duplicate title/artist id3 tags\n\n"
  puts "USAGE: ruby #{$0} <root_directory>"
  puts " e.g.  ruby #{$0} c:\\music"
  exit(0)
end
dir = ARGV[0]

@songs_seen_so_far = Array.new
@mp3_files = Array.new
# read and display infos & tags
Find.find(dir) do |f|
  if (File.file?(f) && (f =~ /\.mp3$/))
    @mp3_files.push(f)
  end
end

@mp3_files.each do |f|
  begin
    Mp3Info.open(f) do |mp3info|
      title = (mp3info.tag.title == nil) ? "unknown" : mp3info.tag.title
      artist = (mp3info.tag.artist == nil) ? "unknown" : mp3info.tag.artist
      cm = (mp3info.channel_mode == nil) ? "unknown" : mp3info.channel_mode
      title.strip!
      artist.strip!
      #puts cm + "|" + title + "-" + artist + "-" + mp3info.bitrate.to_s
      mp3_string = title + "__:__" + artist + "__:__" + cm
      mp3_string = mp3_string + "[" + f.to_s + "]" if (title == "unknown" && artist == "unknown") 
	
      @songs_seen_so_far.push(mp3_string)
      puts mp3_string
    end #Mp3Info.open(f)   
  rescue
    puts "ERROR WITH " + f.to_s + " " + $!
  end
end
