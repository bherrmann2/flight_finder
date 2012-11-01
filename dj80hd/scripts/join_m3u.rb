require "find"
require "ftools"
require "fileutils"

#
# 22 may 2009 jwerwath    Original
#

if (ARGV.length < 2)
  puts "The root directory is searched for m3u files.  All m3u files are"
  puts "Consolidated into one m3u specified by the output file and  "
  puts "dupilcates are removed.  "
  puts "filter is a term used to narrow the list of m3u files gathered."
  puts "for example a fileter of \"bob\" would only read in the m3u files that"
  puts "had \"bob\" in the filename.  Leave it blank to gather all files"
  puts "USAGE: ruby #{$0} <root_dir> <output_file> <filter>"
  puts " e.g.  ruby #{$0} c:\\music c:\\tmp\\all.m3u bob"
  exit(0)
end

dir = ARGV[0]
outfile = ARGV[1]
filter = ARGV[2]

if (!File.exists?(dir) || !File.directory?(dir)) then
  puts "the following either does not exist or is not a directory: " + d
  exit(0)
end

if (!(outfile =~ /\.m3u$/)) then
  puts "the output file must end in .m3u"
  exit(0)
end
puts "FILTER is #{filter}"

outlines = Array.new

#For each file in dir #1 see if it exists in root dir #2
Find.find(dir) do |fname|
  if (fname =~ /\.m3u$/) then
    if (filter && (!(File.basename(fname).include?(filter)))) 
      puts ">>>SKIPING #{fname}"
    else
      puts ">>>TAKING #{fname}"
      f = File.new(fname);
      outlines << f.readlines.reject{|line| line =~ /^#/}
      f.close
    end
  end
end #find

File.open(outfile,'w+') {|f| f.puts outlines.uniq}
puts ">>>Done.  Wrote #{outfile}"                      


