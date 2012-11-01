require 'rubygems'
require 'httpclient'
require 'yaml'
require 'html/sgml-parser'

#while ($content =~ m/href=\"(.*?)\"/gi) {push @hrefs,$1;}
#while ($content =~ m/href=\'(.*?)\'/gi) {push @hrefs,$1;}
#while ($content =~ m/href=([-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)/gi) {push @hrefs,$1;
class LinkGrabber

  def initialize
    @hrefs = Array.new
    @srcs  = Array.new
  end
  #
  # @content is html content as a string
  # @type is the attribute name (href, src, ...)
  def parse(content,type)
    re = Regexp.new(type + "=\"(.*?)\"")
    return content.gsub!(/\s+/,'').scan(re)
  end #parse
end #class LinkGrabber

if (ARGV.length != 1)
  puts "USAGE: ruby #{$0} <absolute_url>"
  puts " e.g.  ruby #{$0} http://vfuk.p1.novarra.co.uk/new.vodafonetest.com/copernicus/Copernicus.htm"
  exit(0)
end
#FIXME - Check if config file exists and give error with example if not there.

config = open('extract_links.conf') {|f| YAML.load(f)}
#puts config.to_yaml

url = ARGV[0]
headers = config['headers']
ua_string  = config['ua_string']   

#FIXME - Need to check the configuration


#config = {'headers' => {'User-Agent' => 'SonyEricssonK800iv/R1ED Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1', 'x-wte-msisdn' => '666'}, 'types' => {'images' => 'true', 'links' => 'false'}}

c = HTTPClient.new(nil, ua_string,nil)
content = c.get_content(url,nil,headers)

puts content;

grabber = LinkGrabber.new
srcs = grabber.parse(content,"src")
puts "---SRCS---\n"
print srcs.join("\n")


#puts content
