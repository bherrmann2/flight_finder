#!/usr/bin/ruby
#
# Collection of functions for dealing with binary content
#

module JrwUtils         

  def fname2lines(fname)
    contents = open(fname) {|f| f.readlines}
    return contents
  end
 
  def fname2string(fname)
    contents = open(fname) {|f| f.read}
    return contents
  end

  def string2fname(s,fname)
    open(fname,'w') {|f| f.puts(s)}
  end

end
