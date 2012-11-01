require "find"
require "ftools"

if (ARGV.length < 1)
  puts "USAGE: ruby #{$0} <root_dir>"
  puts " e.g.  ruby #{$0} c:\\tmp1"
  exit(0)
end

dir1 = ARGV[0]

Find.find(dir1) do |f|
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

