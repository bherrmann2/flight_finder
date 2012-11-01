require "find"
require "ftools"
require "fileutils"

if (ARGV.length != 2)
  puts "USAGE: ruby #{$0} <source_dir> <target_dir>"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2"
  exit(0)
end

dir1 = ARGV[0]
dir2 = ARGV[1]

#Check our input
[dir1,dir2].each do |d|
  if (!File.exists?(d) || !File.directory?(d)) then
    puts "the following either does not exist or is not a directory: " + d
    exit(0)
  end
end


#For each file in dir #1 see if it exists in root dir #2
Find.find(dir1) do |f|
  if (File.exists?(f) && !File.directory?(f))
    basename_for_dir1_file = File.basename(f)
    absolute_pathname_for_dir1_file = f #f.to_s.gsub(/[\/|\\]/,'')
    absolute_pathname_for_dir2_file = f.gsub(dir1,dir2)

    if (File.exists?(absolute_pathname_for_dir2_file) && !File.directory?(absolute_pathname_for_dir2_file))
      if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))
        #FIXME - We are assuming here that the same bite size means the same
        #        file, but really we need some sort of checksum.
        puts "[EXISTS - same size]" + absolute_pathname_for_dir2_file
      elsif (File.size(absolute_pathname_for_dir1_file) > File.size(absolute_pathname_for_dir2_file))
        #Directory where the dir2 file will go
        absolute_directory_for_dir2_file = absolute_pathname_for_dir2_file.gsub(/#{Regexp.escape(File.basename(absolute_pathname_for_dir2_file))}$/,'')
        #Create this directory if needed...
        File.makedirs(absolute_directory_for_dir2_file)
        File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
        if (File.exists?(absolute_pathname_for_dir2_file))
          puts "[EXISTS but COPIED because bigger]" + absolute_pathname_for_dir2_file
        else
          puts "[ERROR!]" + absolute_pathname_for_dir2_file
        end 
      #  mtime_for_dir1_file = File.new(absolute_pathname_for_dir1_file).mtime
      #  mtime_for_dir2_file = File.new(absolute_pathname_for_dir2_file).mtime
      #	if (mtime_for_dir1_file >= mtime_for_dir2_file)
      #    puts "[EXISTS - different size, and newer]" + absolute_pathname_for_dir2_file
      #	else
      #    puts "[EXISTS - different size, but older]" + absolute_pathname_for_dir2_file
      #	end
      else
        puts "[EXISTS NOT COPIED because smaller]" + absolute_pathname_for_dir2_file
      end
    else
      #Directory where the dir2 file will go
      absolute_directory_for_dir2_file = absolute_pathname_for_dir2_file.gsub(/#{Regexp.escape(File.basename(absolute_pathname_for_dir2_file))}$/,'')
      #Create this directory if needed...
      File.makedirs(absolute_directory_for_dir2_file)
      File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
      if (File.exists?(absolute_pathname_for_dir2_file))
        puts "[CREATED]" + absolute_pathname_for_dir2_file
      else
        puts "[ERROR!]" + absolute_pathname_for_dir2_file
      end 
    end
  end
end
