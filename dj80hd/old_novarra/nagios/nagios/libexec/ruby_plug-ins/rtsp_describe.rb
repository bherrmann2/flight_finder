#############################################################################
#  RTSP DESCRIBE CHECK FOR VIDEO SERVERS (NAGIOS PLUGIN)                    #
#  -----------------------------------------------------                    #
#  Example Usage:                                                           #
#  ruby rtsp_describe.rb --host 12.130.107.81                               #
#############################################################################
require 'optparse' #OptionParser
require 'socket' #TCPSocket

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
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

unless (options[:host]) 
  puts "Use --help to get help"
  exit 1
end

#
# This is the entire contents of an RTSP DESCRIBE request for a local test
# file on every video server.  If this file does not exist check that the file
# /home/novarra/tools/healthcheckserver/4sec.flv
# exists on the video server
#
request = "DESCRIBE rtsp://12.130.107.81/video/nocache/ZmlsZTovLy9ob21lL25vdmFycmEvdG9vbHMvaGVhbHRoY2hlY2tzZXJ2ZXIvNHNlYy5mbHY=.3gp RTSP/1.0\x0d\x0a\x0d\x0a"

port = 554 #RTSP port
msg = "OK" 
code = 0

begin
  t = TCPSocket.new(options[:host],port)
  t.print(request)
  response = slurp_http_response(t)
  t.close
  if (response)
    if (response =~ /^RTSP\/1.0 (\d+)/)
      status = $1.to_i
      if (200 != status)
        msg = "CODE " + status.to_s
        code = 1
      end
    else
      msg = "UNEXPECTED RESPONSE."
      code = 2
    end
  else
    msg = "Null response"       
    code = 2
  end
rescue Exception => e
  msg = "Exception " + e.to_s
  code = 2
rescue TimeoutError
  msg = "Timeout."
  code = 2
end

puts msg
exit code
