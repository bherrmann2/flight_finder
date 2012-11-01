require 'rubygems'
require 'optparse' #OptionParser
require 'mysql'
#
# This does not work.   Apparantly with a MySQl object, the first call to
# query is fine (returns MySQL::Result) but after that it just returns MySQL
# object.  I dont know how to reuse a connection for multiple queries.
#
#

times_mutex = Mutex.new
times = Array.new
#Get our options --host HOSTNAME
options = {}
opts = OptionParser.new do |opts|
  opts.on("--host HOST", String,
    "host of database") do |host| 
      options[:host] = host 
  end
  opts.on("--user USER", String,
    "username for DB ") do |user| 
      options[:user] = user 
  end
  opts.on("--pass PASS", String,
    "password for DB ") do |pass| 
      options[:pass] = pass 
  end
  opts.on("--dbname DBNAME", String,
    "name of database") do |dbname| 
      options[:dbname] = dbname 
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    puts "Examples:"
    puts "ruby #{$0} --host localhost --user root --pass secret --dbname test "
    exit
  end
end.parse!

unless (options[:host] || options[:url]) 
  puts "Use --help to get help"
  exit 1
end
options[:pass] ||= ''
sleep_secs = 10
vars = Hash.new
last_reads = 0
last_writes = 0
while (true) do
  db = Mysql.real_connect(options[:host],options[:user],options[:pass],options[:dbname])
  res = db.query('show global status')
 #puts ">>>" + res.class.to_s
  
  res.each do |r| 
    vars[r[0]] = r[1]
    #puts r[0] + " " + r[1] if (r[0] == "Threads_connected" || r[0] == "Threads_running")
    #puts r[0] + " " + r[1] if (r[0] == "Innodb_data_reads" || r[0] == "Innodb_data_writes")
  end
  conns = vars['Threads_connected']
  threads = vars['Threads_running']
  reads = vars['Innodb_data_reads'].to_i
  writes = vars['Innodb_data_writes'].to_i
  reads = vars['Com_select'].to_i
  writes = vars['Com_update'].to_i
  reads_per_sec = (last_reads == 0) ? 0 : (reads.to_f - last_reads.to_f) / sleep_secs.to_f
  writes_per_sec = (last_writes == 0) ? 0 : (writes.to_f - last_writes.to_f) / sleep_secs.to_f
  puts "CONN=#{conns.to_s} THREADS=#{threads.to_s} READS/SEC=#{reads_per_sec.to_s} WRITES/SEC=#{writes_per_sec.to_s}"
  last_writes = writes
  last_reads = reads
  res.free
  sleep sleep_secs
  db.close
end
