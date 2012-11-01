if (!ARGV[0] || !File.exists?(ARGV[0]))
  puts "To VIEW all the dups in <csv_file_name>:"
  puts "USAGE: ruby #{$0} <csv_file_name>"
  puts "To DELETE all the dups in <csv_file_name>:"
  puts "USAGE: ruby #{$0} <csv_file_name> delete"
  exit
end
delete_on = (ARGV[1] && ARGV[1] == "delete")
lines = open(ARGV[0], 'r') {|f| f.readlines}
cols = lines.shift
headers = cols.split(',')
puts cols
songs = Hash.new
#lines[1..3].each do |line|
savings = 0
lines.each do |line|
  begin
  line = line.gsub(/,(\d+),/,',"\1",')
  line = line.gsub(/,(-\d+),/,',"\1",')
  line = line.slice(1,line.size - 1)
  parts = line.split("\",\"")
  song = Hash.new
  headers.each_index {|i| song[headers[i]] = parts[i]}
  key = (song['Title'] + "|" + song['Artist'] + "|" + song['Album']).downcase
  if (songs[key])
    msg = ""
    #msg += ">>>DUP[#{key}]"
    if (song['Bitrate'].to_i > songs[key]['Bitrate'].to_i)
      #msg += "BETTER BR #{song['Bitrate']} vs. #{songs[key]['Bitrate']}"
      path = songs[key]['Path']
      s = File.size(path)
      savings += s
      msg += "\n>>>" + (delete_on ? "DELETE" : "DUP") + " #{path} fsize: #{s.to_s} bitrate #{song['Bitrate']} better than #{songs[key]['Bitrate']}"
      File.delete(path) if delete_on
      songs[key] = song
    else
      #msg += "EQUAL OR WORSE BR #{song['Bitrate']} vs. #{songs[key]['Bitrate']}"
    end
    puts msg unless msg.size == 0
  else
    songs[key] = song
  end
  rescue Exception => e
    puts "ERROR on this line " + line + " " + e.to_s
  end
  #puts song['Artist'] + "|" + song['Title'] + "|" + song['Bitrate']
end
puts "TOTAL SAVINGS: " + savings.to_s
