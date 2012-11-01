require "ftools"
require "fileutils"
require "song"
class Songlist
  attr_accessor :songs
  def initialize
    @songs = Array.new
  end
  def append(song)
    @songs.push(song)
  end
  def find_song(song)
    @songs.each do |s|
      if (song.equals?(s))
        return s    
      end
    end
    return nil
  end
  def find_basename(basename)
    @songs.each do |s|
      if (s.basename == basename)
        return s    
      end
    end
    return nil
  end

  def find_filesize(filesize)
    @ret = Array.new
    @songs.each do |s|
      if (s.filesize == filesize)
        ret.push(s)    
      end
    end
    return ret
  end
  
  def include?(song)
    return self.has_song?(song)
  end
  def has_song?(song)
    s = self.find_song(song)
    return (s == nil) ? false : true
  end
  def as_string
    out = ""
    #FIXME - what is the cool ruby way to do this?
    @songs.each {|s| out = out + "\n" + s.as_string}
    return out + "\n" + self.summary_string
  end
  def summary_string
    #FIXME - What is the cool one-liner ruby way to do this ?
    tot = 0
    filesize_string = "unknown"
    @songs.each {|s| tot = tot + s.filesize}                   
    denominations = {1 => "B", 1024 => "K", (1024 * 1024) => "M", (1024 * 1024 * 1024) => "G"}
    denominations.keys.sort.each do |d|
      if (tot > d.to_i) then
        filesize_string = (tot / d.to_f).to_s + denominations[d].to_s
      end
    end
    
    return "TOTAL FILES:" +  @songs.size.to_s + " TOTAL SIZE: " + filesize_string

  end
  def load_from_dir(dir)
    Find.find(dir) do |f|
      if (Song.music_file?(f))
        self.append(Song.new(f))
      elsif (File.file?(f))
	      #puts ">>>NOT A MUSIC FILE !!!: " + f
      end
    end
  end
  def as_m3u(m3u_filename)
    Songlist.array2m3u(@songs.collect {|s| s.filename}, m3u_filename)
  end
  def Songlist.array2m3u(a,m3u_filename)
    open(m3u_filename,"w").write(a.join("\n"))
  end
end
