require "find"
require "ftools"
require "fileutils"

#
# 15 jul 2011 Original - NOT DONE
#
def niceexit(msg) 
  puts "ERRORS:\n" + msg
  exit
end

if (ARGV.length < 2)
  puts "The Source directory is recursively searched and all the files"
  puts "are copied into the target directory.  Files are not the files"
  puts "USAGE: ruby #{$0} <source_dir> <target_dir>"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2"
  puts ""
  puts "Note: to avoid deleting anything add a 'nodelete' parameter:"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2 nodelete"
  puts ""
  puts "Note: to show all output even same files, use 'same' parameter:"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2 same"
  exit(0)
end

dir1 = ARGV[0]
dir2 = ARGV[1]
nodelete = ARGV[2]

interrupted = false
errorlog = "";

#die peacefully
trap("INT") { interrupted = true }
trap("KILL") { interrupted = true }


#Check our input
[dir1,dir2].each do |d|
  if (!File.exists?(d) || !File.directory?(d)) then
    puts "the following either does not exist or is not a directory: " + d
    exit(0)
  end
end


file_count = 0

#For each file in dir #1 see if it exists in root dir #2
Find.find(dir1) do |f|
  niceexit(errorlog) unless (!interrupted)
  if (File.exists?(f) && !File.directory?(f))
    begin
    file_count = file_count + 1
    basename_for_dir1_file = File.basename(f)
    absolute_pathname_for_dir1_file = f #f.to_s.gsub(/[\/|\\]/,'')
    absolute_pathname_for_dir2_file = f.gsub(dir1,dir2)
    mtime_for_dir1_file = File.new(absolute_pathname_for_dir1_file).mtime

    if (File.exists?(absolute_pathname_for_dir2_file) && !File.directory?(absolute_pathname_for_dir2_file))

      #Get the mtime for dir2 file
      mtime_for_dir2_file = File.new(absolute_pathname_for_dir2_file).mtime
      
      if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))
        #--- CASE 1: BOTH FILES EXIST AND ARE IDENTICAL - DO NOTHING EXCEPT FOR M3U ---
        #FIXME - We are assuming here that the same bite size means the same
        #FOR M3U - overwrite if the contents are different and newer...
	  #&& (!File.identical?(absolute_pathname_for_dir1_file, absolute_pathname_for_dir2_file))
	      if ((mtime_for_dir1_file > mtime_for_dir2_file) && (!File.compare(absolute_pathname_for_dir1_file, absolute_pathname_for_dir2_file)))
          File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          puts "[OVERWRITTEN because it is older and different but same size ]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"
        else
          puts "[IDENTICAL]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")" unless (nodelete != "same")
        end 
              #
      else #FILES ARE OF DIFFERENT SIZE !
        bs = (File.size(absolute_pathname_for_dir1_file) > File.size(absolute_pathname_for_dir2_file)) ? "smaller" : "bigger"

        #if dir1 file newer than dir2
	      if (mtime_for_dir1_file > mtime_for_dir2_file)
          #--- CASE 2: BOTH FILES EXIST AND DIR2 (TARGET) FILE OLDER - OVERWRITE DIR2 ---
          #puts "[EXISTS and is newer]" + absolute_pathname_for_dir1_file
          File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          puts "[OVERWRITTEN (#{bs} & older and different size)]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"

        elsif (mtime_for_dir2_file > mtime_for_dir1_file) #otherwise dir2 file is newer...
          puts "[EXISTS (#{bs} & newer)]" + absolute_pathname_for_dir2_file + " (" +file_count.to_s + ")"
        else
          puts "[EXISTS (different size but same age ?)]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"
        end #if (mtime_for_dir1_file > mtime_for_dir2_file)
      end #if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))

    #--- CASE 3: DIR2 FILE DOES NOT EXIST - CREATE IT ---                    
    else
      #Directory where the dir2 file will go
      absolute_directory_for_dir2_file = absolute_pathname_for_dir2_file.gsub(/#{Regexp.escape(File.basename(absolute_pathname_for_dir2_file))}$/,'')

      #Create this directory if needed...
      File.makedirs(absolute_directory_for_dir2_file)

      #Copy the file
      puts "[STARTED]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"
      File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)

      #Report it
      if (File.exists?(absolute_pathname_for_dir2_file))
        puts "[CREATED]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"
      else
        puts "[ERROR on COPY/CREATE]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"
      end 
    end
    rescue Exception => e
      puts "[EXCEPTION]" + e.to_s
      errorlog = errorlog + e.to_s + "\n";
    end
  end #if (File.exists?(f) && !File.directory?(f))
end #find

#FIXME - Have to remove empty directories.
if (nodelete != "nodelete")
  Find.find(dir2) do |f|
    niceexit(errorlog) unless (!interrupted)
    if (File.exists?(f))
      absolute_pathname_for_dir2_file = f
      absolute_pathname_for_dir1_file = f.gsub(dir2,dir1)
      if (File.exists?(absolute_pathname_for_dir1_file))
        # Nothing to do
      else #file does not exist in dir1 so delete it from dir2
        FileUtils.rm_rf(absolute_pathname_for_dir2_file)
        if (File.exists?(absolute_pathname_for_dir2_file))
          puts "[ERROR on DELETE]" + absolute_pathname_for_dir2_file
        else
          puts "[DELETED]" + absolute_pathname_for_dir2_file
        end
      end
    end #file exists
  end #find
end #if (nodelete != "nodelete")

niceexit(errorlog)
