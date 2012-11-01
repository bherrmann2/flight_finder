require 'rubygems'
require 'httpclient'

c = HTTPClient.new(nil, "Agent 666","dj80hd@scissorsoft.com")
content = c.get_content("http://scissorsoft.com/cgi-bin/printenv.pl",nil,{"X-NUMBER" => "666"})
puts content
