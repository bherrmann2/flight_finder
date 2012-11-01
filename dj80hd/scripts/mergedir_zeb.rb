require "find"
require "ftools"
require "fileutils"

#
# 29 Jun 2008 jwerwath    Forget about file size just use mod time.
#

if (ARGV.length < 2)
  puts "USAGE: ruby #{$0} <source_dir> <target_dir>"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2"
  puts " Note: To delete all files in target_dir that are NOT in source_dir\n"
  puts " add the parameter 'delete' to the end of the command like this:\n"
  puts "       ruby #{$0} c:\\tmp1 c:\\tmp2 delete"
  puts " To delete files from source_dir AFTER they are copied to target_dir,\n"
  puts " add the parameter 'move' to the end of the command like this:\n"
  puts "       ruby #{$0} c:\\tmp1 c:\\tmp2 move"
  exit(0)
end

dir1 = ARGV[0]
dir2 = ARGV[1]
options = ARGV[2]

#Check our input
[dir1,dir2].each do |d|
  if (!File.exists?(d) || !File.directory?(d)) then
    puts "the following either does not exist or is not a directory: " + d
    exit(0)
  end
end

dir1_files = Array.new
files_2_delete = Array.new
Find.find(dir1) do |f|
  if (File.exists?(f) && !File.directory?(f))
    basename_for_dir1_file = File.basename(f)
    absolute_pathname_for_dir1_file = f #f.to_s.gsub(/[\/|\\]/,'')
    dir1_files << absolute_pathname_for_dir1_file
    #puts ">>>FOUND #{dir1_files.size.to_s} #{absolute_pathname_for_dir1_file}"
  end
end

#For each file in dir #1 see if it exists in root dir #2
dir1_files.each do |absolute_pathname_for_dir1_file|
    f = absolute_pathname_for_dir1_file
    absolute_pathname_for_dir2_file = f.gsub(dir1,dir2)

    fp = File.new(absolute_pathname_for_dir1_file)
    mtime_for_dir1_file = fp.mtime
    fp.close                        

    if (File.exists?(absolute_pathname_for_dir2_file) && !File.directory?(absolute_pathname_for_dir2_file))

      #Get the mtime for dir2 file
      mtime_for_dir2_file = File.new(absolute_pathname_for_dir2_file).mtime
      
      if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))
        #--- CASE 1: BOTH FILES EXIST AND ARE SAME SIZE
        if (options == "move")
          files_2_delete << absolute_pathname_for_dir1_file
          puts "[QUEUED FOR DELETE #{files_2_delete.size.to_s}] " + absolute_pathname_for_dir1_file
        #FIXME - We are assuming here that the same bite size means the same
        #FOR M3U - overwrite if the contents are different and newer...
	      elsif ( (mtime_for_dir1_file > mtime_for_dir2_file) && (! (FileUtils.compare_file(absolute_pathname_for_dir1_file, absolute_pathname_for_dir2_file)) ))
          File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          puts "[OVERWRITTEN because it is older ]" + absolute_pathname_for_dir2_file
        end 
      else #FILES ARE OF DIFFERENT SIZE !

        #if dir1 file newer than dir2
	      if (mtime_for_dir1_file > mtime_for_dir2_file)
          #--- CASE 2: BOTH FILES EXIST AND DIR2 (TARGET) FILE OLDER - OVERWRITE DIR2 ---
          #puts "[EXISTS and is newer]" + absolute_pathname_for_dir1_file
          File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)
          puts "[OVERWRITTEN (different size & older)]" + absolute_pathname_for_dir2_file
          if (options == "move")
            files_2_delete << absolute_pathname_for_dir1_file
            puts "[QUEUED FOR DELETE #{files_2_delete.size.to_s}] " + absolute_pathname_for_dir1_file
          end #endif options == move

        elsif (mtime_for_dir2_file > mtime_for_dir1_file) #otherwise dir2 file is newer...
          puts "[EXISTS (different size & newer)]" + absolute_pathname_for_dir2_file
        else
          puts "[EXISTS (different size but same age ?)]" + absolute_pathname_for_dir2_file
        end #if (mtime_for_dir1_file > mtime_for_dir2_file)
      end #if (File.size(absolute_pathname_for_dir1_file) == File.size(absolute_pathname_for_dir2_file))

    #--- CASE 3: DIR2 FILE DOES NOT EXIST - CREATE IT ---                    
    else
      #Directory where the dir2 file will go
      absolute_directory_for_dir2_file = absolute_pathname_for_dir2_file.gsub(/#{Regexp.escape(File.basename(absolute_pathname_for_dir2_file))}$/,'')

      #Create this directory if needed...
      File.makedirs(absolute_directory_for_dir2_file)

      #Copy the file
      File.copy(absolute_pathname_for_dir1_file,absolute_pathname_for_dir2_file)

      #Report it
      if (File.exists?(absolute_pathname_for_dir2_file))
        puts "[CREATED]" + absolute_pathname_for_dir2_file
        if (options == "move")
          files_2_delete << absolute_pathname_for_dir1_file
          puts "[QUEUED FOR DELETE #{files_2_delete.size.to_s}] " + absolute_pathname_for_dir1_file
        end #endif options == move
      else
        puts "[ERROR on COPY/CREATE]" + absolute_pathname_for_dir2_file
      end 
      
    end
end #find

if (options == "move")
  files_2_delete.each do |f|
    FileUtils.rm_rf(f)
    if (File.exists?(f))
      puts "[ERROR on DELETE]" + f + " (" + File.size(f).to_s + ")"
    else
      puts "[DELETED]" + f
    end
  end #each
end #endif

#FIXME - Have to remove empty directories.
if (options == "delete")
  Find.find(dir2) do |f|
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
    end
  end #Find
end #if delete
