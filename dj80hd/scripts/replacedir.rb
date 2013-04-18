require "find"
require "ftools"
require "fileutils"

#
# 22 jan 2009 jwerwath    Original based on mergedir_zeb.
# 05 jan 2013 jwerwath    Add keep_existing param and comment
# FIXME - Use a try catch for each copy.
#
#
def niceexit(msg) 
  puts "ERRORS:\n" + msg
  exit
end

if (ARGV.length < 2)
  puts "A target directory is completely replaced with a source directory"
  puts "USAGE: ruby #{$0} <source_dir> <target_dir>"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2"
  puts ""
  puts "Note: to avoid changing anything that exists 'keep_existing' parameter:"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2 keep_existing"
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

switches = []
if (ARGV.length > 2)
  switches = ARGV[2..ARGV.length]
end

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

    #--- FILE EXISTS IN BOTH PLACES
    #------------------------------
    if (File.exists?(absolute_pathname_for_dir2_file) && !File.directory?(absolute_pathname_for_dir2_file))

      mtime_for_dir2_file = File.new(absolute_pathname_for_dir2_file).mtime
     
      #--- FILES EXIST IN BOTH PLACES AND HAVE SAME SIZE     
      #----------------------------------------------------- 
      if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))
        #--- FILES BOTH EXIST, SAME SIZE, FIRST FILE IS NEWER
        #----------------------------------------------------
	if ((mtime_for_dir1_file > mtime_for_dir2_file) && (!File.compare(absolute_pathname_for_dir1_file, absolute_pathname_for_dir2_file)))
          File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          #--- * CASE 1: FILE EXISTS IN BOTH PLACES, DIR 1 is NEWER
          #--------------------------------------------------------
          puts "[OVERWRITTEN because it is older and different but same size ]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"
        #--- * CASE 2: FILE EXISTS IN BOTH PLACES, DIR 2 is NEWER OR SAME
        #----------------------------------------------------------------
        else
          #Only let user know if they specified the same switch
          puts "[IDENTICAL Size and Same if not newer]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")" unless (!switches.include?("same"))
        end 
              #
      #--- FILES BOTH EXIST BUT ARE OF DIFFERENT SIZE !
      #------------------------------------------------
      else 
        bs = (File.size(absolute_pathname_for_dir1_file) > File.size(absolute_pathname_for_dir2_file)) ? "smaller" : "bigger"

        #--- FILES BOTH EXIST BUT ARE OF DIFFERENT SIZE DIR 2 is OLDER!
        #--------------------------------------------------------------
	if (mtime_for_dir1_file > mtime_for_dir2_file)
          #--- * CASE 3 * BOTH FILES EXIST AND DIR2 (TARGET) FILE OLDER - 
          #--- OVERWRITE DIR2 ---
          #puts "[EXISTS and is newer]" + absolute_pathname_for_dir1_file
          File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          puts "[OVERWRITTEN (#{bs} & older)]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"

        elsif (mtime_for_dir2_file > mtime_for_dir1_file) #otherwise dir2 file is newer...
          #--- * CASE 4 * BOTH FILES EXIST AND DIR2 (TARGET) FILE NEWER - 
          #--- LEAVE DIR2 ---
          puts "[EXISTS (#{bs} & newer)]" + absolute_pathname_for_dir2_file + " (" +file_count.to_s + ")"
        else
          #--- This should NEVER HAPPEN
          puts "[UNEXPECTED (different size but same age ?)]" + absolute_pathname_for_dir2_file + " (" + file_count.to_s + ")"
        end 
      end 

    #--- CASE 5: DIR2 FILE DOES NOT EXIST - CREATE IT ---                    
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

#Unless user has specified the nodelete switch, remove all files.
if (!switches.include?("nodelete"))
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
