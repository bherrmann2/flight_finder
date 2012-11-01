#USAGE = "USAGE: ruby deleteall.rb <suffix>\ne.g. ruby deleteall.rb m4p\n" 
#suffix = "." + ARGV[0]
# #FIXME - If suffix is nil exit.
#if (suffix == nil)
#  puts USAGE
#  exit
#end
ms_offset = 10000
ms_interval = 1000
num_samples = 100
burstiness = ARGV[0].to_i
burst_interval = ARGV[1].to_i
num_bursts = num_samples / burst_interval
samples = (0 .. num_samples -1).to_a
samples.each do |s|
	puts s
end

new_pos_a = []
(0 .. num_bursts - 1).to_a.each do |i|
  start_sample = i * burst_interval
  end_sample = start_sample + burst_interval - 1
  midpoint = start_sample + ((burst_interval -1)/2)
  (0 .. burst_interval - 1).to_a.each do |k|
    pos = k + start_sample
    if (pos < midpoint)
      new_pos = pos + ((burstiness * (midpoint  - pos))/100)
    elsif (pos > midpoint)
      new_pos = pos - ((burstiness * (pos - midpoint))/100)
    else
      new_pos = pos
    end
    new_pos_a << new_pos
    puts "s=" + start_sample.to_s + " e=" + end_sample.to_s + "  m=" + midpoint.to_s + " pos=" + pos.to_s + " NEW POS=" + new_pos.to_s
  end
end
h = Hash.new(0)
(0 .. num_samples - 1).to_a.each do |s|
  h[s] = ""
end
new_pos_a.each do |n|
  h[n] = h[n] + "*"
end
(0 .. num_samples - 1).to_a.each do |s|
  puts s.to_s + ":" + h[s]
end
  


