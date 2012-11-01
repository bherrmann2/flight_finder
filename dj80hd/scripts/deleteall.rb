require "find"
USAGE = "USAGE: ruby deleteall.rb <dir> <suffix>\ne.g. ruby deleteall.rb m4p\n" 
if (ARGV[0] == nil || ARGV[1] == nil)
  puts USAGE
  exit
end
suffix = "." + ARGV[1]
#FIXME - Make sure first arg is dir and make sure we got the right #
#of args
root_dir = ARGV[0]
Find.find(root_dir) do |f|
  ARGV.each do |a|
    if (File.extname(f) == "." + a)
      #puts "FOUND: " + f
      begin
      if (File.delete(f) == 1)
        puts "DELETED: #{f}"
      else
        puts "COUNT NOT DELETE: #{f}"
      end
      rescue 
        puts "COUNT NOT DELETE: #{f}"
      end
    end
  end
end
#FIXME - Build a list of files and allow user to confirm.
#FIXME - Remove all empty directories.
Find.find(root_dir) do |f|
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

