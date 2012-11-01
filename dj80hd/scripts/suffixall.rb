require "find"
USAGE = "USAGE: ruby #{$0} <root_dir> <old_suffix> <new_suffix>\ne.g. ruby #{$0} . m4a mp4\n" 
if (ARGV[0] == nil || ARGV[1] == nil || ARGV[2] == nil)
  puts USAGE
  exit
end
old_suffix = "." + ARGV[1]
new_suffix = "." + ARGV[2]
#FIXME - Make sure first arg is dir and make sure we got the right #
#of args
root_dir = ARGV[0]
Find.find(root_dir) do |f|
  if (File.extname(f) == old_suffix)
    new_f = f.gsub(/#{old_suffix}$/,new_suffix)
    begin
      #puts "OLD #{f}"
      File.rename(f,new_f)
      puts "NEW #{new_f}"
    rescue Exception => e
      puts "FAIL #{new_f} " + e.to_s
    end
  end
end

