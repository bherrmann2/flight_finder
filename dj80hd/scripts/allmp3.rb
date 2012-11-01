require "mp3info"
require "find"
require "ftools"

 # read and display infos & tags
 Find.find('.') do |f|
   if (File.file?(f) && (f =~ /\.mp3$/))
     begin
       Mp3Info.open(f) do |mp3info|
       title = (mp3info.tag.title == nil) ? "unknown" : mp3info.tag.title
       artist = (mp3info.tag.artist == nil) ? "unknown" : mp3info.tag.artist
       cm = (mp3info.channel_mode == nil) ? "unknown" : mp3info.channel_mode
       puts cm + "|" + title + "-" + artist + "-" + mp3info.bitrate.to_s
       end   
     rescue
	   puts "ERROR WITH " + f.to_s
     end
   end
 end


