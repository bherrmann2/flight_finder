require "find"
require "ftools"
require "fileutils"

if (ARGV.length < 1)
  puts "USAGE: ruby #{$0} <m3u_filename> [<random_m3u_filename>]"
  puts " e.g.  ruby #{$0} songs.m3u songs_rand.m3u"
  puts " if no random_m3u_filename is specified, one will be generated and placed"
  puts " in the local directory." + ARGV.length.to_s
  exit(0)
end

m3u_file_in = ARGV[0]

#default file out
m3u_file_out_base = File.basename(m3u_file_in) + "_random.m3u"
m3u_file_in_dir  = File.dirname(m3u_file_in)
m3u_file_out      = File.expand_path(m3u_file_out_base,m3u_file_in_dir)


#overide file out if user specified it.
m3u_file_out = ARGV[1] unless (ARGV.length < 2)

#Check user input for m3u file  
if (!File.exists?(m3u_file_in))
  puts (m3u_file_in + " does not exist")
  exit(0)
end 
if not (m3u_file_in =~ /\.m3u$/)   
  puts (m3u_file_in + " does not end in '.m3u'")
  exit(0)
end 

#get the contents of a file as an array of lines
lines = open(m3u_file_in) {|f| f.readlines()}
lines.uniq! #Remove Dups
lines.delete_if {|x| (x =~ /^#/) or (x =~ /^\s+$/) }

#make the m3u lines absolute to avoid problems with relative paths
lines = lines.map{|x| File.expand_path(x.chop,m3u_file_in_dir)}

#Also makes sure they are real files (FIXME - Warn if not ?)
lines = lines.find_all{|x| File.file? x}

#randomize
lines = lines.sort_by {rand}

#write them in random order to the output file.
File.open(m3u_file_out, 'w') do |file|
  file.puts lines
end

puts "DONE! Results in " + m3u_file_out
