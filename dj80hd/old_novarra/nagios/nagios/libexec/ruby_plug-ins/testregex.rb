require 'yaml'
regex = ARGV[0]
file = ARGV[1]

file_as_string = open(ARGV[1]) {|f| f.read}
file_as_string.gsub!(/\n/,'')
file_as_string.gsub!(/\r/,'')
r = Regexp.new(ARGV[0])
matches = file_as_string.scan(r)
#puts YAML::dump(matches)
if (matches && matches[0]) 
  matches.each {|m| puts "GOT #{m[0]}"}
else
  print "content=#{file_as_string}\n No matches on " + ARGV[0] 
end
