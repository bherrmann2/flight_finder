require "find"
require "ftools"
require "fileutils"
if (ARGV.length != 1)
  puts "USAGE: ruby rename_the_in_dirs <root_dir>"
  puts " e.g.  ruby rename_the_in_dirs c:\\music\2sort"
  exit(0)
end
rootdir  = ARGV[0]
if (!File.directory?(rootdir))
  puts "ERROR.  The following is not a directory: " + rootdir
  exit(1)
end

#d = Dir.new(rootdir)
#FIXME - This does not seem to delete all empty directories.
Dir.entries(rootdir).each do |de|
#FIXME - find a platform independant way to do the directory separator
old_dir = rootdir + "\\" + de.to_s
new_dirname = ""
#Find.find(rootdir) do |f|
	#puts "DE = " + de
  if (File.directory?(old_dir))
	  #puts "dir"
    if (de =~ /^The\s+(.*) - (.*)/)
      new_dirname = rootdir + "\\" + $1.strip + ",The - " + $2.strip
      #puts "one"
    elsif (de =~ /^The\s+(.*)-(.*)/)
      new_dirname = rootdir + "\\" + $1.strip + ",The - " + $2.strip
      #puts "two"
    elsif (de =~ /^The\s+(.*)$/)
      new_dirname = rootdir + "\\" + $1.strip + ",The"
      #puts "three"
    end
    if (new_dirname != "")
      puts "Moving old dir = '" + old_dir + "' to new dir '" + new_dirname +"'"
      FileUtils.mv(old_dir,new_dirname,:force => true)
    end
  end
end
