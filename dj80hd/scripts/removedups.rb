require "find"
require "ftools"
require "fileutils"
require 'digest/md5'
require 'digest/sha1'


#
# 19 Jul 2008 jwerwath   Initial 
# 19 Jul 2008 jwerwath   Updated to remove dups of files with same basename
# 09 Sep 2009 jwerwath   Better Error Handling and performance and feedback
# 19 Sep 2009 jwerwath   delete option 
#
# FIXME - 2 dir option not complete

def md5(f)
  return Digest::MD5.hexdigest(File.read(f))
end	

if ((ARGV.length < 1) || (ARGV[0] != "show" && ARGV[0] != "delete"))
  puts "Removes duplicate music files in a directory tree."
  puts ""
  puts "USAGE: ruby #{$0} <mode> <dir1> <dir2> ... <dirN>"
  puts " e.g.  The following command shows all the duplicate files that "
  puts "       have the current directory or c:\\tmp as a root.         "
  puts "ruby #{$0} show . c:\\tmp"
  puts ""
  puts " e.g.  The following command does the same but actually deletes "
  puts "       duplicates.  preference for the file to save will be the "
  puts "       first directoy listed therefore dumps .\\foo.txt and     "
  puts "       c:\\tmp\\foo.txt results in c:\\tmp\\foo.txt being deleted"
  puts "ruby #{$0} delete . c:\\tmp"
  exit(0)
end
count = 0
savings = 0
mode = ARGV[0]
dirs = ARGV[1..-1]
delete_on = (mode == "delete")
sizes_to_filename_arrays = Hash.new
#For each file in each directory, if you find a duplicate in the same directory,
#delete the duplicate
dirs.each do |dir|
  Find.find(dir) do |f|
    if (File.exists?(f) && !File.directory?(f))
      count += 1
      puts ">>>#{count} files processed. #{savings.to_s} bytes saved." if (count.divmod(100)[1] == 0)
      basename_for_file = File.basename(f)
      absolute_pathname_for_file = f 
      extname = File.extname(f)            
      size_bytes = File.size(f)
      if (sizes_to_filename_arrays[size_bytes]) 
        begin
          a = sizes_to_filename_arrays[size_bytes]
          #md5_1 = md5(f)
          a.each do |f2|
            next if (f == f2)
            #md5_2 = md5(f2)
            #if (md5_1 == md5_2)
            word = delete_on ? "DELETING" : "DUP"
            if (File.compare(f,f2))
              puts "#{word} #{f} - it is the same as #{f2}"
              FileUtils.rm(f) unless !delete_on
              savings += size_bytes
            elsif (File.basename(f) == File.basename(f2))
              puts "#{word} #{f} - same size/name as #{f2}"
              FileUtils.rm(f) unless !delete_on
              savings += size_bytes
            else
              a.push(f)
            end
          end#a.each
        rescue Exception => e2
          puts e2.to_s + " on file " + f
        rescue 
          puts "PROBLEM WITH THIS FILE: " + f
        end
      else #we have not seen this file size yet
        a = Array.new
        a.push(f)
        sizes_to_filename_arrays[size_bytes] = a
      end
    end #if (File.exists?(f) && !File.directory?(f))
  end #find
end #each dir

