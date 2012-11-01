#THIS DOES NOT WORK YET !
require "find"
require "ftools"
require "fileutils"

if (ARGV.length < 2)
  puts "USAGE: ruby #{$0} <root_dir_to_delete_files_from> <root_dir_to_look_for_dups>"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2"
  puts " Note: To delete all files in target_dir that are NOT in source_dir\n"
  puts " add the parameter 'delete' to the end of the command like this:\n"
  puts "       ruby #{$0} c:\\tmp1 c:\\tmp2 delete"
  exit(0)
end

delete_dir = ARGV[0]
find_dir = ARGV[1]
options = ARGV[2]

#Check our input
[delete_dir,find_dir].each do |d|
  if (!File.exists?(d) || !File.directory?(d)) then
    puts "the following either does not exist or is not a directory: " + d
    exit(0)
  end
end

delete_canidates = Array.new
dup_canidates = Hash.new
Find.find(delete_dir) do |f|
  if (File.exists?(f) && !File.directory?(f))
    puts "DELETE CANDIATE: " + f
    delete_canidates << f
  end
end
Find.find(find_dir) do |f|
  if (File.exists?(f) && !File.directory?(f))
    dup_canidate =   File.basename(f).to_s + "[" + File.size(f).to_s + "]"
    #puts "DUP CANIDATE: " + dup_canidate
    dup_canidates[dup_canidate] = f 
  end
end
#dup_canidates_text = dup_canidates.join("\n")
delete_canidates.each do |f|
  #grep_for = Regexp.new("^" + File.basename(f).to_s + "[" + File.size(f).to_s + "]")
  grep_for = File.basename(f).to_s + "[" + File.size(f).to_s + "]"
  puts "TRY TO FIND " + grep_for
  if (dup_canidates.keys.include?(grep_for))
    puts "DUP: " + f + " found in " + dup_canidates[grep_for] + " size=" + File.size(dup_candidates[grep_for]).to_s
  else
    puts "ORIG: " + f + " size=" + File.size(f).to_s
  end 
end
puts dup_canidates.keys.join("\n")
#FIXME - Have to remove empty directories.
#if (options == "delete")
#  Find.find(dir2) do |f|
#    if (File.exists?(f))
#      absolute_pathname_for_dir2_file = f
#      absolute_pathname_for_dir1_file = f.gsub(dir2,dir1)
#      if (File.exists?(absolute_pathname_for_dir1_file))
#        # Nothing to do
#      else #file does not exist in dir1 so delete it from dir2
#        FileUtils.rm_rf(absolute_pathname_for_dir2_file)
#	if (File.exists?(absolute_pathname_for_dir2_file))
#          puts "[ERROR on DELETE]" + absolute_pathname_for_dir2_file
#	else
#          puts "[DELETED]" + absolute_pathname_for_dir2_file
#	end
#      end
#    end
#  end #Find
#end
