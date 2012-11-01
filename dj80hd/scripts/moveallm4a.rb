require "mp3info"
require "find"
require "ftools"

 # read and display infos & tags
 Find.find('.') do |f|
   if (File.file?(f) && (f =~ /\.m4a$/))
     begin
       #FIXME - dont hard code this.
       FileUtils.move(f,"g:\\2sort\\m4a")
       #File.delete(f)
     rescue
	   puts "ERROR WITH " + f.to_s + $!
     end
   end
 end


