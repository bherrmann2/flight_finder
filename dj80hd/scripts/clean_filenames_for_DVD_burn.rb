require "find"
require "ftools"

def clean_name(name)
  #FIXME - Put this all in one regex
  name = name.gsub(/;/,'_')
  name = name.gsub(/'/,'')
  name = name.gsub(/"/,'')
  name = name.gsub(/:/,'_')
  name = name.gsub(/\*/,'')
  name = name.gsub(/\?/,'_')
  name = name.gsub(/</,'')
  name = name.gsub(/>/,'')
  if (name.length > 106)
    #FIXME - we assume a 3 char suffix which may not be the case !
    name = name[0,101] + name[-4,4]
    
  end
  return name
end

USAGE = "USAGE: ruby #{$0} <root directory>\nThis script starts at the given root directory and truncates any filenames more than 106 characters and replaces any special characters.\n" 

#CHECK INPUT
if (ARGV.length < 1)
  puts USAGE
  exit(0)
end

d = ARGV[0]
if (!File.exists?(d) || !File.directory?(d)) then
  puts "the following either does not exist or is not a directory: " + d
  exit(0)
end


Find.find(d) do |f|
  if (File.file?(f))
    begin
      name = f.to_s
      basename = File.basename(f)
      cleaner_basename = clean_name(basename)
      if (cleaner_basename != basename)
        cleaner_name = f.to_s.gsub(basename,cleaner_basename)
        result = 0;
        result = File.rename(name,cleaner_name)
        puts "#{name}\n..." + ((result ==0) ? "SUCCESSFULLY" : "UNSUCCESSFULLY") + " renamed to...\n#{cleaner_name}\n\n";
      end
    rescue
      puts "ERROR ON : #{f}" + $!
    end
  end
end
#File.rename("afile", "afile.bak")
#


