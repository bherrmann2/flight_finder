require "find"
require "ftools"
require "fileutils"

class Song
  attr_accessor :filename, :filesize, :basename
  def initialize(filename)
    @filename = filename
    @basename = File.basename(filename)
    @filesize = File.size(filename)
  end
  def equals?(song)
    return ((song.basename == @basename) && (song.filesize == @filesize))
  end
  def as_string
    return @basename + " (" + @filesize.to_s + ") "#+ @basename
  end
end


class Songlist
  attr_accessor :songs
  def initialize
    @songs = Array.new
  end
  def append(song)
    @songs.push(song)
  end
  def has_song?(song)
    @songs.each do |s|
      if (song.equals?(s))
        return true
      end
    end
    return false
  end
  def as_string
    out = ""
    #FIXME - what is the cool ruby way to do this?
    @songs.each {|s| out = out + "\n" + s.as_string}
    return out
  end
  def summary_string
    #FIXME - What is the cool one-liner ruby way to do this ?
    tot = 0
    filesize_string = "unknown"
    @songs.each {|s| tot = tot + s.filesize}                   
    denominations = {1 => "B", 1024 => "K", (1024 * 1024) => "M", (1024 * 1024 * 1024) => "G"}
    denominations.keys.sort.each do |d|
      if (tot > d.to_i) then
        filesize_string = (tot / d.to_i).to_s + denominations[d].to_s
      end
    end
    
    return "TOTAL FILES:" +  @songs.size.to_s + " TOTAL SIZE: " + filesize_string

  end
end
def is_music_file(filename)
	return (File.file?(filename) && ((filename =~ /\.mp3$/i) || (filename =~ /\.wma$/i) ||(filename =~ /\.wav/i)))
end

if (ARGV.length != 3)
  puts "USAGE: ruby mp3dir [diff|merge] <directory 1> <directory 2>"
  puts " e.g.  ruby mp3dir diff c:\\tmp1 c:\\tmp2"
  exit(0)
end

cmd  = ARGV[0]
dir1 = ARGV[1]
dir2 = ARGV[2]

#Check our input
[dir1,dir2].each do |d|
  if (!File.exists?(d) || !File.directory?(d)) then
    puts "the following either does not exist or is not a directory: " + d
    exit(0)
  end
end


music_files = {dir1 => Songlist.new, dir2 => Songlist.new}

#Get a file list for each directory
[dir1,dir2].each do |d|
  Find.find(d) do |f|
    if (is_music_file(f) && !File.directory?(f))
      music_files[d].append(Song.new(f))
    else
      if (!File.directory?(f))
        puts "The following is not an music file: " + f
      end                          
    end
  end
end

#Get the list of the music files in each directory
in_1_not_in_2 = Songlist.new
in_2_not_in_1 = Songlist.new
in_1_and_in_2 = Songlist.new
in_2_and_in_1 = Songlist.new
music_files[dir1].songs.sort_by{|f| f.basename}.each do |s1|
  if music_files[dir2].has_song?(s1)
    in_1_and_in_2.append(s1) 
  else
    in_1_not_in_2.append(s1)
  end
end
music_files[dir2].songs.sort_by{|f| f.basename}.each do |s2|
  if music_files[dir1].has_song?(s2)
    in_2_and_in_1.append(s2) 
  else
    in_2_not_in_1.append(s2)
  end
end

puts "\n---\nIN 2 NOT IN 1:"
puts in_2_not_in_1.as_string + "\n" + in_2_not_in_1.summary_string
puts "\n---\nIN 1 NOT IN 2:"
puts in_1_not_in_2.as_string + "\n" + in_1_not_in_2.summary_string
puts "\n---\nIN 2 AND IN 1:"
puts in_2_and_in_1.as_string + "\n" + in_2_and_in_1.summary_string
puts "\n---\nIN 1 AND IN 2:"
puts in_1_and_in_2.as_string + "\n" + in_1_and_in_2.summary_string


if (cmd == "merge")
  puts "Merging directory #{dir1} to #{dir2}"
  in_1_not_in_2.songs.sort_by{|f| f.basename}.each do |s|
	 #puts "COPY #{s.filename} to #{dir2}"
    #Create Path if needed
    if (s.filename =~ /^#{Regexp.escape(dir1)}(.*)#{Regexp.escape(s.basename)}/)
	    #if (s.filename =~ /c:[\/|\\]{1,1}tmp[\/|\\]{1,1}test[\/|\\]{1,1}test1/)
      newdir = dir2 + "/" + $1.gsub(/^[\/|\\]/,'') #Remove / or \ at beginning
      File.makedirs(newdir)
      File.copy(s.filename,newdir)
      targetfile = newdir + "/" + s.basename
      if (File.exists?(targetfile))
        puts "COPIED: " + s.basename
      else
        puts "ERROR COPY FAILED FOR: " + s.basename + " TARGET FILE WAS " + targetfile
      end
    else
      puts "ERROR INCORRECT FILENAME FORMAT: " + s.filename
    end
    #Copy file
  end
  
  #as_string + "\n" + in_1_not_in_2.summary_string
  
end




