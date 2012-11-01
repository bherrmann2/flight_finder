require 'webrick'
include WEBrick

class MyServlet < HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.body = "<HTML>PING! #{Time.now.to_s}</HTML>"
    res['Content-Type'] = "text/html"
  end
  def do_POST(req,res)
    res.body = "<HTML>PING! #{Time.now.to_s}</HTML>"
    res['Content-Type'] = "text/html"
    puts ">>>" + req.to_s
    data = req.query['data']
    data ||= "NONE"
    puts ">>>" + data
   
  end

end

if (ARGV[0])
  s = HTTPServer.new(:Port  => ARGV[0].to_i)
  s.mount("/", MyServlet)
  trap("INT"){ s.shutdown }
  s.start
else
  puts "USAGE: ruby #{$0} port_number\ne.g. ruby #{$0} 3128"
end
