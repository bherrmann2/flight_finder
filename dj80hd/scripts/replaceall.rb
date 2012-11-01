require "c:\\scripts\\jrw_utils.rb"
include JrwUtils
#
# 09 Jun 2009 jwerwath    Initial version
#

if (ARGV.length < 3)
  puts "USAGE: ruby #{$0} <old_word> <new_word> <filename>"
  puts " e.g.  ruby #{$0} necssary necessary  c:\\tmp\\report.txt"
  puts " e.g.  ruby #{$0} 'C:\\music\\dj80hd_loves\\' '' c:\\music\\dj80hd_loves\\_current.m3u"

  exit(0)
end

old_word = ARGV[0]
new_word  = ARGV[1]
fname = ARGV[2]
puts "Replacing '#{old_word}' with '#{new_word}' in file #{fname}"
contents = fname2string(fname)
new_contents = contents.gsub(old_word,new_word)
puts new_contents
string2fname(new_contents,fname)
