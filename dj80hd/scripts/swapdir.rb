if (ARGV.length < 2)
  puts "USAGE: ruby #{$0} <dir 1> <dir 2>"
  puts " e.g.  ruby #{$0} c:\\tmp1 c:\\tmp2"
  puts " Used to make two directories contain the union of their contents.\n"
  exit(0)
end

dir1 = ARGV[0]
dir2 = ARGV[1]
#FIXME - How to not hard code this ?
cmd = "ruby c:\\scripts\\mergedir.rb"
cmd1 = "#{cmd} #{dir1} #{dir2}"
cmd2 = "#{cmd} #{dir2} #{dir1}"
system(cmd1)
system(cmd2)
