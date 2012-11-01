require "ftools"
require "fileutils"

class Song
  attr_accessor :filename, :filesize, :basename
  def initialize(filename)
    @filename = os_specific_pathname(filename)
    @basename = File.basename(filename)
    @filesize = File.size(filename)
  end
  def equals?(song)
    return ((song.basename == @basename) && (song.filesize == @filesize))
  end
  def as_string
    return @basename + " (" + @filesize.to_s + ") "#+ @basename
  end
  def Song.music_file?(filename)
	return (File.file?(filename) && ((filename =~ /\.mp3$/i) || (filename =~ /\.wma$/i) ||(filename =~ /\.wav/i)))
  end
  def os_specific_pathname(pathname)
    #FIXME - Does this do a global replace ?
    if (ENV['OS'] =~ /indows/)
      return pathname.gsub(/\//,"\\")
    else
      return pathname
    end
  end
end
