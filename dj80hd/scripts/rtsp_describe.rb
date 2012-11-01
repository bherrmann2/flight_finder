require 'optparse' #OptionParser
require 'socket' #TCPSocket
#############################################################################
#  RTSP DESCRIBE CHECK FOR VIDEO SERVERS (NAGIOS PLUGIN)                    #
#  -----------------------------------------------------                    #
#  Example Usage:                                                           #
#  ruby rtsp_describe.rb --host 12.130.107.81                               #
#############################################################################

def get_describe_request(rtsp_url)
  return "DESCRIBE #{rtsp_url} RTSP/1.0\x0d\x0a\x0d\x0a"
end

def get_location(response)
  if (response =~ /^RTSP\/1.0 (\d+)/)
    status = $1.to_i
    if (302 == status)
       if (response =~ /Location: (\S+)/)
         return $1       
       end
    end
  end
  return nil
end

def get_describe_response(request,host,port)
  begin
    t = TCPSocket.new(host,port)
    t.print(request)
    response = slurp_http_response(t)
    t.close
  rescue Exception => e
    msg = "Exception " + e.to_s
    code = 2
  rescue TimeoutError
    msg = "Timeout."
    code = 2
  end
  return (code == 2) ? msg : response
end
#
# Take a socket as input and slurp up any http (actually rtsp in this case)
# response that there is in the buffer and return it as a string
#
def slurp_http_response(socket)
  b = socket
  response = ""
  clen = 0
  line = "dummy"
  while (true) do
    line = b.readline
    response += line + "\x0d\x0a"
    if (line =~ /Content-Length: (\d+)/i)
      clen = $1.to_i
    end
    break if (line.chomp.size <= 0)
  end #while
  response += b.read(clen) unless (clen == 0)
  return response
end


#Get our options --host HOSTNAME
options = {}
opts = OptionParser.new do |opts|
  opts.on("--host HOST", String,
    "ip of videoserver to check") do |host| 
      options[:host] = host 
  end
  opts.on("--url URL", String,
    "url to check (overrides host)") do |url| 
      options[:url] = url 
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    puts "Examples:"
    puts "ruby #{$0} --url rtsp://dmzosx001.dpa.act.gov.au/medium"
    exit
  end
end.parse!

unless (options[:host] || options[:url]) 
  puts "Use --help to get help"
  exit 1
end

#
# This is the entire contents of an RTSP DESCRIBE request for a local test
# file on every video server.  If this file does not exist check that the file
# /home/novarra/tools/healthcheckserver/4sec.flv
# exists on the video server
#
#FIXME - Should this be localhost or 127.0.0.1 ?

rtsp_url = "rtsp://12.130.107.81/video/nocache/ZmlsZTovLy9ob21lL25vdmFycmEvdG9vbHMvaGVhbHRoY2hlY2tzZXJ2ZXIvNHNlYy5mbHY=.3gp"
host = options[:host]
if (options[:url])
  rtsp_url = options[:url]
  if (rtsp_url =~ /rtsp:\/\/([^\/]+)\//)
    host = $1
    if (host =~ /(\d+\.\d+\.\d+\.\d+):\d+/)
      host = $1
    end
  else
    puts "This is not a valid rtsp url: #{rtsp_url}"
    exit 1
  end
end
request = get_describe_request(rtsp_url)
response = get_describe_response(request,host,554)
if (response)
  location = get_location(response)
  while (location)
    puts response
    response = get_describe_response(get_describe_request(location),host,554)
    location = get_location(response)
  end
else
  response = "NIL RESPONSE"
end
puts response
