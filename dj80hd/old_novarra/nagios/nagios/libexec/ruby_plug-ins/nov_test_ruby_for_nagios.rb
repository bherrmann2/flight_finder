#!/usr/bin/ruby --
#
# Find the path where we can look for requires.
#
root_file = __FILE__
root_file = root_file.gsub(/\\/,'/')
root_dir = File.dirname(root_file)


config_file = (ARGV[0]) ? ARGV[0] : '3hk_video_sites.conf'
config_file = root_dir + "/" + config_file unless (config_file && File.exists?(config_file))
config_file = root_dir + "/ruby_plug-ins/" + config_file unless (config_file && File.exists?(config_file))
$: << File.dirname(config_file) 
code = 0
begin
  require 'video_check'
  nagios_plugin = VideoCheck.new
rescue Exception => e
  puts e.to_s
  code = 1
ensure
  puts "config=" + config_file + " exists=" + File.exists?(config_file).to_s + " ROOT_DIR=" + root_dir + " ROOT_FILE=" + root_file + " code=" + code.to_s
end
exit code
