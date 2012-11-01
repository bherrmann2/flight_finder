require "mp3info"

 Dir.open('.') {|d| d.each {|f| puts f}}

 # Task one - get an array with all the .mp3 files in this directory.
 mp3s = []
 d = Dir.open('.') {|d| d.each {|f| mp3s << f if (f =~ /\.mp3$/)}}
 #mp3s.each {|f| puts ">>>" + f}
 
 # read and display infos & tags
 mp3s.each do |mp3file|
   newfilename = ""
   Mp3Info.open(mp3file) do |mp3info|
     newfilename =
     ((mp3info.tag.tracknum == nil) ? "0" : mp3info.tag.tracknum.to_s)
     newfilename += "-"
     newfilename += ((mp3info.tag.artist == nil)? "artist" : mp3info.tag.artist)
     newfilename += "-"
     newfilename += ((mp3info.tag.album == nil) ? "album" : mp3info.tag.album)
     newfilename += ".mp3"
   end
   File.rename(mp3file,newfilename)
 end

#FIXME - Cant seem to call this method.
def self.get_new_file_name(tracknum,artist,album)
     ((tracknum == nil) ? "0" : tracknum.to_s)
     + "-"
     + ((artist == nil) ? "artist" : artist)
     + "-"
     + ((album == nil) ? "album" : album)
     + ".mp3"
end
 # read/write tag1 and tag2 with Mp3Info#tag attribute
 # when reading tag2 have priority over tag1
 # when writing, each tag is written.

#Mp3Info.open("foo.mp3") do |mp3|
# puts mp3.tag.title
# puts mp3.tag.artist
# puts mp3.tag.album
# puts mp3.tag.tracknum

# mp3.tag.title = "track title"
# mp3.tag.artist = "artist name"

#end

#Mp3Info.open("foo.mp3") do |mp3|
# # you can access four letter v2 tags like this
# puts mp3.tag2.TIT2
# mp3.tag2.TIT2 = "new TIT2"
# # or like that
# mp3.tag2["TIT2"]

# # at this time, only COMM tag is processed after reading and before writing
# # according to ID3v2#options hash
# mp3.tag2.options[:lang] = "FRE"
# mp3.tag2.COMM = "my comment in french, correctly handled when reading and writing"
#end

