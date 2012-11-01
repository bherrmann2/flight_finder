#NOT DONE - download of URL did not get all content in body for some reason
require "find"
require "ftools"
require "fileutils"
require "net/http" 

def is_music_file(filename)
	return (File.file?(filename) && ((filename =~ /\.mp3$/i) || (filename =~ /\.wma$/i) ||(filename =~ /\.wav/i)))
end

if (ARGV.length != 2)
  puts "USAGE: ruby #{$0} <file_or_url_containing_mp3_absolute_urls> <directory_to_put_mp3_files>"
  puts " e.g.  ruby #{$0} c:\\playlist.xml c:\\tmp"
  puts " e.g.  ruby #{$0} http://www.film-m.de/sound_player/playlist.xspf c:\\tmp"
  exit(0)
end

file_or_url  = ARGV[0]
dir = ARGV[1]
content = ""


#Check our input
if (!File.exists?(dir) || !File.directory?(dir)) then
  puts "the following either does not exist or is not a directory: " + dir
  exit(0)
end
if (file_or_url =~ /^http:\/\//)
  resp = Net::HTTP.get_response(URI.parse(file_or_url))
  content = resp.body
  puts resp.body.size
  puts resp['Content-Length']
  puts resp['Content-Type']
  #open(file_or_url).read()           
else
  if File.exists?(file_or_url)
    content = open(file_or_url){ |f| f.read}
  else
    puts "the following is not a valid file or url: " + file_or_url
    exit (0)
  end
end
puts content
puts "-----"
#content.gsub(/http:\/\/.+\.mp3/) {|m| puts m.to_s}

