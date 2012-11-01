require "find"
require "ftools"
require "fileutils"

#
# 29 Jun 2008 jwerwath    Forget about file size just use mod time.
#

if (ARGV.length < 2)
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
  begin
  if (File.exists?(f) && !File.directory?(f))
    basename_for_dir1_file = File.basename(f)
    absolute_pathname_for_dir1_file = f #f.to_s.gsub(/[\/|\\]/,'')
    absolute_pathname_for_dir2_file = f.gsub(dir1,dir2)
    mtime_for_dir1_file = File.new(absolute_pathname_for_dir1_file).mtime

    if (File.exists?(absolute_pathname_for_dir2_file) && !File.directory?(absolute_pathname_for_dir2_file))

      #Get the mtime for dir2 file
      mtime_for_dir2_file = File.new(absolute_pathname_for_dir2_file).mtime
      
      if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))
        #--- CASE 1: BOTH FILES EXIST AND ARE SAME SIZE - DO NOTHING EXCEPT FOR M3U ---
        #FIXME - We are assuming here that the same bite size means the same
        #FOR M3U - overwrite if the contents are different and newer...
	      if ( (mtime_for_dir1_file > mtime_for_dir2_file) && (File.extname(absolute_pathname_for_dir2_file) == ".m3u") && (! (FileUtils.compare_file(absolute_pathname_for_dir1_file, absolute_pathname_for_dir2_file)) ))
          #File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          puts "[OLDER BUT SAME SIZE]" + absolute_pathname_for_dir2_file
        end 
              #
      else #FILES ARE OF DIFFERENT SIZE !

        #if dir1 file newer than dir2
	      if (mtime_for_dir1_file > mtime_for_dir2_file)
          #--- CASE 2: BOTH FILES EXIST AND DIR2 (TARGET) FILE OLDER - OVERWRITE DIR2 ---
          #puts "[EXISTS and is newer]" + absolute_pathname_for_dir1_file
          #File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          puts "[DIFFERENT SIZE AND OLDER]" + absolute_pathname_for_dir2_file

        elsif (mtime_for_dir2_file > mtime_for_dir1_file) #otherwise dir2 file is newer...
          puts "[DIFFERENT SIZE AND NEWER]" + absolute_pathname_for_dir2_file
        else
          puts "[DIFFERENT SIZE SAME AGE]" + absolute_pathname_for_dir2_file
        end #if (mtime_for_dir1_file > mtime_for_dir2_file)
      end #if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))

    #--- CASE 3: DIR2 FILE DOES NOT EXIST - CREATE IT ---                    
    else
      #Directory where the dir2 file will go
      puts "[ONLY EXISTS IN " + dir1 + "]" + absolute_pathname_for_dir1_file
      absolute_directory_for_dir2_file = absolute_pathname_for_dir2_file.gsub(/#{Regexp.escape(File.basename(absolute_pathname_for_dir2_file))}$/,'')

    end
  end #if (File.exists?(f) && !File.directory?(f))
  rescue Exception => e
    puts "[ERROR on #{f}]" + e.to_s
  end
end #find
