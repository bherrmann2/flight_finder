require "find"
require "ftools"
USAGE = "USAGE: ruby bubble.rb\nThis script 'bubbles' up all files under this directory to the current directory essentially removing all directory structure.\n" 

Find.find('.') do |f|
  if (File.file?(f))
    begin
    if (File.dirname(f) == '.')
      puts "KEPT IN ROOT: #{F}"
    else
      File.move(f,'.')
      puts "MOVED: #{f}"
    end
    rescue
    puts "COUNT NOT MOVE: #{f}" + $!
    end
  end
end
#FIXME - This does not seem to delete all empty directories.
Find.find('.') do |f|
  if (File.directory?(f))
    d = Dir.new(f)
    e = d.entries.length
    if (e == 2)
      begin
        Dir.delete(f)
	puts "DELETED DIRECTORY: #{f}"
      rescue
	puts "ERROR COULD NOT DELETE DIRECTORY: #{f} " + $!
      end
    end
  end
end

