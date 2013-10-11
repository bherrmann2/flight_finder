require 'nagios_plugin'
require 'socket'
require 'uri'
require 'aca_client'
#
# Nagios plugin to check video sites.
# A video site will be loaded, then the plugin will search for video links on 
# that site.  One of those video links will be followed and then the script will
# expect to find an rtsp link somewhere in the content.
#
# This Check is driven from the nov_check_video_sites.rb script
#
# Parameters of the video check to be performed are supplied in config_file
# which is the name of a file containing configuration in yaml format and this
# is passed to the start method to perform the check.
#
# ONE random selection from this file is actually checked.
# If the client wishes to check ALL of the video sites, the _check_all_ 
# method must be used.
#
#
# Here is an example of the format of the configuration file.
# ________________________________________________________________________
# 3hk.proxy.novarra.com:
#   mode: normal
#   port: 8827
#   ua_string: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1
#   headers:
#      Cookie: Novarra-Device-ID=666;SESSIONID=6
#      Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8  #  
#   video_sites:
#     - uri: http://youtube.com
#       regex: href=\"(\S+\watch\?v=\w+)\"
#     - uri: http://hk.video.yahoo.com
#       regex: href=\"(\S+\?id=\d+)\"
# ________________________________________________________________________
#
#
# The class extends the NagiosPlugin class so it will record a return code
# (2=ERROR, 1=WARNING, 0=OK) like a normal nagios plugin should and issue this code
# when the exit method is called.
# The first line of STDOUT will be the Success/Error status message.
#
# Example usage:
#
# # - Create the plugin
# video_check_plugin = VideoCheck.new
#
# # - Configure and start it
# video_check_plugin.start('3hk_video_sites.conf')
#
# # - Report the status
# video_check_plugin.exit
#
# 
class VideoCheck < NagiosPlugin

  #
  # Configure and run the VideoCheck
  # The video check will check a random site from the config file.
  # If it fails, it will try another before issueing an error.
  #
  def start(config_file)
    #First get everything the user passed in.
    config = get_config(config_file)
    if (should_check_all?(config))
      check_all(config)
    else
      check_random(config)
    end 
  end #start

  def should_check_all?(config)
    config.keys.each do |aca|
      flag = config[aca]['check_all']
      #puts "FLAG #{aca} is " + ((flag)? flag.to_s : "null")
      return true if (flag)
    end
    return false
  end
  def check_random(config)
    #Do the first check
    do_random_check(config)                

    first_exit_code = @exit_code
    first_msg = @exit_msg

    #If something went wrong perform a sanity check so that we might have a better
    #idea of what is really going on...
    if (first_exit_code != 0)
      #do another check
      do_random_check(config)
      if (@exit_code != 0)
        @exit_msg = "Double Failure 1." + first_msg + " 2." + @exit_msg
      else                  
        @exit_code =  1 #JUST A WARNING becauce the second check was OK.
        @exit_msg = "Single Failure " + first_msg
      end                     
    end
  end #check_random


  #
  # Actually reads the configuration file and sets up a check for a random url 
  # on a random aca in the configuration
  #
  def do_random_check(config)
    begin
      url = ""

      #Get a random aca from the config
      aca = config.keys[rand(config.keys.size)]

      #Get the configuration for that aca
      aca_config = config[aca] #aca_hostname
      mode = aca_config['mode'] #proxy/normal
      port = aca_config['port'] #port (usually 80 or 8827)
      ua_string = aca_config['ua_string'] #user agent to use
      headers = aca_config['headers'] #any other custom http req hdrs
      video_sites = aca_config['video_sites'] #video sites
      
      #Get a random uri/regex from that aca's configuration
      url_regex = video_sites[rand(video_sites.size)]
      url = url_regex['uri']      
      video_link_regex = url_regex['regex']      

      #Perform the check on that random video site for that random aca
      do_check(aca,port,headers,ua_string,mode,url,video_link_regex)

    rescue Exception => e
      warning("Config Exception " + e.to_s +  " url=" + url)
    end
  end #do_random_check

  #
  # Reads the config file which is in YAML format
  # and creates a config object
  #
  def get_config(config_file)
    config = open(config_file) {|f| YAML.load(f)}
  end

  #
  # only for unit testing - Tests the WHOLE configuration file of video links
  # sets @exit_code to 0 if everything is OK
  #
  def check_all(config)
    ok = true
    error_msg = ""
    config.keys.each do |aca|
      c = config[aca]
      c['video_sites'].each do |video_site|
        do_check(aca,c['port'],c['headers'],c['ua_string'],c['mode'],video_site['uri'],video_site['regex'])
        #puts @exit_msg + " " + video_site['uri']
        ok = ok & (@exit_code == 0)
        error_msg = error_msg + @exit_msg unless (@exit_code == 0)
      end
    end
    @exit_code = (ok) ? 0 : 1
    @exit_msg = (ok) ? "ALL OK!" : error_msg
  end


  #
  # Actually perform the video check given all the parameters.
  #
  def do_check(aca,port,headers,ua_string,mode,url,video_link_regex)
    begin

      #Bail out if called did not provide a regex for checking video content
      error("nil video_link_regex") unless (video_link_regex)
      return unless (video_link_regex)

      #Create a client to talk to this ACA
      aca_client = AcaClient.new(aca,port,headers,ua_string,mode)

      #Load the URL through the ACA.
      resp = aca_client.load(url)

      #If the response is ok...
      if (resp.http_status_code == 200)

        #Remove newlines for easy regex matching
        content = remove_newlines(resp.http_content)

        #Apply the regex to find the video links, bomb out if none found.
        matches = get_matches(content,video_link_regex)
        error("no matches for #{video_link_regex} loading url #{url} in content:#{content}") unless (matches && matches.size > 0)
        return unless (matches && matches.size > 0)

        #At this point we have links that we expected to find for videos
        #Construct an absolute URL out of the video link we found with the regex
        #Note: for Brew this is a p pointer which we do not resolve.
        first_match = matches[0] #The first one we found should work...

        #Load video URL and make sure we find an rtsp link
        #puts "***LOADING*** #{first_match}"
        resp = aca_client.load_relative(resp,first_match)
        if (resp.http_status_code == 200)
          rtsp_url = extract_rtsp_url(aca_client,resp.http_content)
          if (rtsp_url != nil)
            #If we got an actual rtsp url, perform an RTSP describe
            first_line_rtsp_resp = get_first_line_of_rtsp_describe(rtsp_url)

            #If the RTSP response is ok, we are good, else it is an error
            if ((first_line_rtsp_resp != nil) &&  first_line_rtsp_resp.include?("RTSP/1.0 200 OK"))
              success( "-OK-" + url + " (" + rtsp_url + ")" )
            else
              first_line_rtsp_resp ||= "nil" #Avoid exception
              error("RTSP Response: " + first_line_rtsp_resp.chomp + " " + rtsp_url)
            end
          else #We did not find an rtsp url !
            content = content.split(/</).join("\n<")
            error("Could not find rtsp content from url #{first_match}\n#{content}")
          end
        else #The request for the video url did not work.
          error("HTTP " + resp.http_status_code.to_s + " url=" + url)
        end
      else #The request for the top url (e.g. youtube.com) did not work.
        error("HTTP " + resp.http_status_code.to_s + " url=" + url)
      end
    rescue Timeout::Error
      warning("Timeout Error")
    rescue Exception => e
      trace = (e.backtrace) ? e.backtrace.join("\n") : "(no trace)"
      warning("Exception " + e.to_s + trace + " url=" + url)
    end
  end #do_check

  #
  # Take an aca_client and the content of a response received by that
  # client and extract the first rtsp url we can find.
  #
  def extract_rtsp_url(aca_client,content)
     content = remove_newlines(content)
     #note: brew sends objects with src attributes, 
     #clientless sends href links.
     if (aca_client.is_brew?)
       if (content =~ /src=\"(rtsp:\/\/\S+\.3gp)\"/)
         return $1
       else
         return nil
       end
     else
       if (content =~ /href=\"(rtsp:\/\/\S+\.3gp)\"/)
         return $1
       else 
         return nil
       end
     end
  end #extract_rtsp_url

  #
  # Returns the first line of the rtsp response for the given rtsp url
  # On error an exception string is returned.
  #
  def get_first_line_of_rtsp_describe(rtsp_url)
    begin
      cmd = "DESCRIBE #{rtsp_url} RTSP/1.0\nCseq: 1\n\n"
      if (rtsp_url =~ /^rtsp:\/\/([^\/]+)\//)
        host = $1.split(':')[0]
        c = TCPSocket.open(host,554)
        c.send(cmd,0)
        first_line = c.recv(100).split("\n")[0]
        c.close
        return first_line
      else
        return "Invalid rtsp url: #{rtsp_url}"
      end
    rescue Timeout::Error => t
      return t.to_s
    rescue Exception => e
      return e.to_s
    end
  end

  #
  # Returns an array for all the matches on string s for a given regex.
  # NOTE: regexp_string is expected to contain one and only one grouping
  # e.g. href=\"(\S+)\"
  #
  def get_matches(s,regexp_string)
    return nil unless (s != nil && regexp_string != nil)
    r = Regexp.new(regexp_string)
    matches = s.scan(r)
    return matches[0]
  end

  #
  # Strips all newline chars from a string
  #
  def remove_newlines(content)
     return nil if not (content)
     return content.gsub(/[\r\n]+/,'')
  end

end #VideoCheck Class
