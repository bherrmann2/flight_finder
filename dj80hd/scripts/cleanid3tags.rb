require "mp3info"
require "find"
require "ftools"
@total_length = 0
def puts2(s)
	(s==nil) ? "nil" : s
end
def clean_mp3_info(filename)
	#puts "=====" + filename + "====="
  begin
  Mp3Info.open(filename) do |mp3|
	  #puts "ENCODE:   " + mp3.bitrate.to_s + "/" + mp3.channel_mode + " " + ((mp3.vbr) ? "VBR":"")
	  #puts "TAG1?:    " + puts2(mp3.hastag1?.to_s)
	  #puts "TAG2?:    " + puts2(mp3.hastag2?.to_s)
    title = mp3.tag1.title
    if (title == nil)
      title = mp3.tag2.TIT2
    end
    if (title == nil)
      title = mp3.tag.title
    end
    artist = mp3.tag1.artist
    if (artist == nil)
      artist = mp3.tag2.TPE2
    end
    if (artist == nil)
      artist = mp3.tag.title
    end

    if ((title == nil) && (artist == nil))
      puts ">>>>>THIS TRACK IS NIL:" + filename
    else
      mp3.tag.title = title
      mp3.tag1.title = title
      mp3.tag2.TIT2  = title
      mp3.tag.artist= artist
      mp3.tag1.artist = artist
      mp3.tag2.TPE2 = artist 
      mp3.close
      puts "UPDATED: " + title + " by " + artist
    end
    #puts "TITLE: " + puts2(mp3.tag.title)
    #puts "ALBUM: " + puts2(mp3.tag.album)
    #puts "ARTIST: " + puts2(mp3.tag.artist)
    #puts "TITLE 1:  " + puts2(mp3.tag1.title)
    #puts "ARTIST 1: " + puts2(mp3.tag1.artist)
    ##puts "ALBUM 1:  " + puts2(mp3.tag1.album)
    #puts "TITLE 2:  " + puts2(mp3.tag2.TIT2)   
    #puts "ARTIST 2: " + puts2(mp3.tag2.TPE2)  
    #puts "ALBUM 2:  " + puts2(mp3.tag2.TALB) 
    #puts "Length:  " +puts2(mp3.length.to_s)
    @total_length += mp3.length
  end
  rescue
	  puts "!!!ERROR!!!: " +$!
  end
  #puts "=========================="
end

def is_mp3_file(filename)
	return (File.file?(filename) && (filename =~ /\.mp3$/i))
end
def show_mp3_directory(dir)
  Find.find(dir) do |f|
    if (is_mp3_file(f) && !File.directory?(f))
      clean_mp3_info(f)
    else
      puts "The following is not an mp3 file: " + f
    end
  end
end
if (ARGV.length == 0)
  ARGV[0] = '.'
end

if (is_mp3_file(ARGV[0]))
  show_mp3_info(ARGV[0])
elsif (File.directory?(ARGV[0]))
  show_mp3_directory(ARGV[0])
else
  puts "ERROR the following is not the name of an mp3 file or valid directory: " . ARGV[0]
end
puts "Total Seconds: " + @total_length.to_s
puts "Hours: " + (@total_length/60/60).to_s
