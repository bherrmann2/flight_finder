require 'webrick'

include WEBrick
#
# There are two web interafaces to this tool.
#
# 1 is a nagios interface that reports the error rate
# 2 is the reporting interface.
#
# This class is an HTTP server that provides both of these interfaces.
#
class MyServlet < HTTPServlet::AbstractServlet
  alias :do_POST :do_GET
  def do_GET(req,res)
    puts "Got ONE!"
    res.status = 200
    res['Content-Type'] = 'text/html'
    res.body = "<html><body><b>It works !</b></body></html>";
  end
end


class WebInterface
  attr_reader :port
  def initialize(port)
    #FIXME - Catch exceptions here
    @port = port
    fatal_stderr_logger = Log.new($stderr, Log::FATAL)
    null_logger = Log.new(nil)            
    @server = HTTPServer.new(:Port => port, :Logger => fatal_stderr_logger)
    @server.mount('/',MyServlet)
  end

  def start
    #Thread.new do
      @server.start  #FIXME - Is server already in its own thread ?
   # end
  end

  #FIXME - In main program handle the TERM and INT traps to shut this down
  def shutdown
    @server.shutdown
  end
end#class WebInterface

if (ARGV.length != 1)
  puts "USAGE: ruby #{$0} <port>"
  puts " e.g.  ruby #{$0} 8080"
  exit(0)
else
  WebInterface.new(ARGV[0]).start
end



