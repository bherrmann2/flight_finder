#!/usr/bin/ruby --

#This is what ruby thinks our root dir is
root_dir = File.dirname(__FILE__.gsub(/\\/,'/'))

#Provide a default for the config file if a config file is specified, an aboslute path is expected.
config_file = (ARGV[0]) ? ARGV[0] : '3hk_video_sites.conf'

#If the config file does not exist, try finding it in the ruby_plug-ins directory
config_file = root_dir + "/ruby_plug-ins/" + config_file unless (config_file && File.exists?(config_file))

if (config_file)
  $: << File.dirname(config_file) 
  require 'video_check'
  nagios_plugin = VideoCheck.new
  nagios_plugin.start(config_file)
  nagios_plugin.exit
else
  puts "USAGE: ruby #{$0} abosolute_path_to_config_file\ne.g. ruby #{$0} /usr/local/groundwork/nagios/libexec/ruby_plug-ins/3hk_video_sites.conf"
  exit 1
end

