#FIXME _ NOT DONE !
#
#require "find"
require "ftools"

DB_FILENAME = "c:\\all.txt"
lines = open(DB_FILENAME) {|f| f.readlines}
hitlines = lines.find_all do |line|
  ARGV.find_all {|w| line.upcase.include?(w.upcase)}.length == ARGV.length
end
puts hitlines
