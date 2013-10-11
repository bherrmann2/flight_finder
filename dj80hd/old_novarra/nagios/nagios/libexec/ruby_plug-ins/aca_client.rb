require 'httpclient'
require 'yaml'          
require 'uri'           

#
# A specialized HTTPClient that is configured to talk to an ACA via HTTP 
#
class AcaClient < HTTPClient

  #used for testing only
  attr_accessor :aca, :aca_port, :ua_string, :headers

  #
  # shutdown should be called on all AcaClients when kill sig is trapped
  #
  def shutdown
    @killed = true
  end

  #
  # Constructor for AcaClient.   This is public, and can be used directly,
  # However, it may be fore conveniend to use the 
  # AcaClientFactory::create_aca_client method
  #
  # @aca - the hostname or ip of the aca e.g. vfuk.p1.novarra.co.uk
  # @aca_port
  # @headers - additional http headers to send up with the request
  #            e.g. {'x-wte-msisdn' => '4322853901'}
  # @ua_string - User-Agent that should be sent in the User-Agent req. header
  # @mode ('normal' or 'proxy') the mode of operation of the ACA
  #
  def initialize(aca,aca_port,headers,ua_string,mode = 'normal')
    @killed = false #Flag for thread dealth
    @aca = aca
    @mode = mode
    @aca_port = aca_port
    @ua_string = ua_string
    @headers = headers
    proxy = (@mode == 'proxy') ? "http://" + @aca + ":" + @aca_port.to_s : nil
    super(proxy,@ua_string,nil)
  end


  def is_brew?
    return (@headers['NOVARRA-DEVICE-TYPE'] == 'BREW')
  end
 
  #
  # Load a page through the Aca          
  # [url] - url to load (DOES NOT include ACA stuff in it)
  # [msisdn] - msisdn to use when sending the headers.
  #
  # Returns an AcaResponse Object
  #
  def load(url, msisdn = nil)

    #If the url is a number we assume this is a p-pointer and the user is clicking
    if (url =~ /^(\d+)$/)
      return click($1.to_s)
    end

    #Otherwise...
    #Get the actual URL to load imploying all are knowledge of the aca
    #For example: url http://lp.org becomes http://aca.novarra.com:8827/lp.org
    #If the Aca Client is configured with mode='normal', aca='aca.novarra.com'
    #and 'port'='8827'
    url = actual_url_to_load(url)

    #Begin by following all redirects to find the actual URL to load
    return get_aca_response(url,msisdn)
  end #load

  def get_aca_response(url,msisdn = nil)
    page_start = Time.now.to_i
    begin
      resp = get_resp_follow_redirects(url,msisdn)
      return AcaResponse.new(resp,page_start,url)
    rescue Timeout::Error
      code = 606
      msg = "PAGE TIMEOUT"
      return AcaResponse.new(nil,page_start,url,code,msg)
    rescue Exception => e
      code = 601
      msg = "PAGE ERROR " + $! + ((e.backtrace[0]) ? e.backtrace[0] : "")
      puts msg
      return AcaResponse.new(nil,page_start,url,code,msg)
    end
   
    #Handle any unexpected errors 
    code = 602
    msg = "PAGE ERROR: Unknown"
    return AcaResponse.new(nil,time_ms,url,code,msg)
  end

  def load_relative(aca_resp,relative_url)
    if (is_brew?)
      click(aca_resp,relative_url)
    else
      load(resolve(aca_resp.base_href,relative_url))
    end
  end
  def resolve(base,relative)
    return (is_brew?) ? relative.to_s : URI::join(base,relative).to_s
  end

  #
  # Click is only used for BREW clients that use obbml and p-pointers
  #
  def click(aca_resp,p_pointer)
    if (is_brew?)
      @headers['NOVARRA-EVENT-TYPE'] = "Click;" + p_pointer.to_s
      @headers['REFERER'] = aca_resp.base_href
      if (aca_resp.http_header('Novarra-Page-Id') =~ /(\d+)/)
        @headers['NOVARRA-PAGE-ID'] = $1.to_i
      end
      url = "http://" + @aca.to_s + ":" + @aca_port.to_s
      body = nil
      page_start = Time.now.to_i
      #puts ">>>>>>>>>>>CLICKING " + p_pointer.to_s + YAML.dump(@headers)
      resp = post(url, body, @headers)
      return AcaResponse.new(resp,page_start,url)
      #resp = get_aca_response(url)
      @headers.delete('NOVARRA-EVENT-TYPE')
      @headers.delete('REFERER')               
      @headers.delete('NOVARRA-PAGE-ID')
      return resp
    else
     raise "Only BREW is supported for click"
    end
  end
#-----------------------------------------------------------------------------
  private
#-----------------------------------------------------------------------------
  #
  # Remove the http:// or https:// from a url
  #
  def remove_protocol_from_url(url)
    return url.sub(/^http:\/\//,'').sub(/^https:\/\//,'')
  end
  
  #
  # Replace the _MSISDN_ placeholder with an acutal MSISDN
  #
  def get_headers(msisdn = nil)
    return nil if (@headers == nil)
    copy = Hash.new                                   
    @headers.each_pair do |k,v|
      v = (v == '_MSISDN_' && msisdn != nil) ? msisdn : v
      copy[k] = v
    end
    return copy
  end

  #
  # Get an HTTP response and automatically follow any redirects
  #
  def get_resp_follow_redirects(url,msisdn = nil)
    raise "bad url" if (url == nil)
    retries = 0
    redirected_urls = Array.new
    while (retries < 10)
      nil_query = nil
      return nil if @killed #Implement Thread death
      #puts "GETTING>>>" + url + " HEADERS= " + YAML::dump(get_headers)
      resp = get(url,nil_query,get_headers)
      raise "bad resp" if (resp == nil)
      if HTTP::Status.redirect?(resp.status)
        retries += 1
        location_header = resp.header['location']
        raise "no location header resp #{url}" if not location_header
        location_url = resp.header['location'][0]
        raise "no location url for hdr #{location_header}" if not location_url
        raise "redirect is same as url '#{url}'" if (url == location_url)
        url = URI.parse(location_url)
        raise "nil url from location '#{location_url}'" if (url == nil)
        raise "infinate redirect @#{retries.to_s}:'#{url}'" if redirected_urls.include?(url)
	      redirected_urls << url
      else
        raise "nil url" if (url == nil)
        raise "nil resp" if (resp == nil)
        resp.final_url = url                      
        return resp
      end
    end
    raise "#{retries.to_s} redirects (" + redirected_urls.join(',') + ")"

  end

  #
  # Determine the actual url to request based on proxy mode, url, server, etc.
  #
  def actual_url_to_load(url)
    if (@aca == nil)
      return url
    #If the URL already contains the ACA, use that
    elsif (url.include?(@aca))
      return url
    else
      #url = remove_protocol_from_url(url)
      return (@mode == 'proxy') ? url :
      "http://" + @aca + ":" + @aca_port.to_s + "/" + remove_protocol_from_url(url)
    end
  end

end 

#
# This extends the class that is used for HTTP Responses.
# It adds 'final_url' parameter which tells where all the redirects ended up.
#
class HTTP::Message
  attr_accessor :final_url
  @final_url = nil
end

class AcaResponse

  #mainly for testing
  attr_accessor :resp,:time_ms,:url,:error_code,:error_msg

  def initialize(resp,page_start_ms,url,error_code = 0, error_msg = nil)
    @resp = resp
    @time_ms = Time.now.to_i - page_start_ms
    @url = url
    @error_code = error_code
    @error_msg = error_msg
  end

  def final_url
    return (@resp != nil && @resp.final_url != nil) ? @resp.final_url : url
  end

  def http_status_code
    return (@resp != nil) ? @resp.status : error_code
  end

  def http_header(header_name)
    return (@resp != nil && @resp.header != nil ) ?  @resp.header[header_name][0] : nil
  end

  def http_content
    return (@resp != nil) ? @resp.content : nil                       
  end

  def base_href 
    absolute_url = final_url
    if (http_content =~ /<base href="(\S+)"/)
       absolute_url = $1
    end
    return absolute_url
  end

  #nil if no error
  def error_msg
    return @error_msg
  end

end

#
# Factory for creating ACA Clients.
# This factory uses a configuration file (aca_client_factory.conf by default)
# to configure a bunch of 'prototype' clients.  That is, clients based on 
# a certain customer.   e.g. '3hk.proxy.novarra.com'
#
# the factory method is create_aca_client
class AcaClientFactory
   def initialize(config_filename = 'aca_client_factory.conf')
     @config = open(config_filename) {|f| YAML.load(f)}
   end

   def prototype_names
     return @config.keys
   end

   #
   # Create an AcaClient instance based on the prototype_hostname.
   # the input, 'c' can be one of the following
   # 1. A String represending the prototype (e.g. '3hk.proxy.novarra.com')
   #
   # If more control is needed over the configuration one can pass in a hash
   # with the following parameters
   # - prototype : prototype on which client is based (e.g. '3hk.proxy.novarra.com')
   # - aca: actual location of aca (e.g. 10.1.1.43) if nil the prototype is used
   # - ua_string: User-Agent string to use in User-Agent Header
   #              if nil, the User-Agent specified for the prototype is used.
   # - port: The port on which the ACA is listening.  If nil, the port of the
   #         prototype is used.
   # - headers: Hash containing extra http headers to be sent with each request.
   # - mode: 'normal' or 'proxy'; the mode the aca is running in
   #
   #
   # Examples:
   #
   # # Create a client for '3hk.proxy.novarra.com'
   # c = factory.create_aca_client('3hk.proxy.novarra.com')
   #
   # # Create a client for a 3HK server load running locally on port 80
   # # send up an extra X-Foo header set to 'Bar'
   # c = factory.create_aca_client({'prototype' => '3hk.proxy.novarra.com', 'aca' => '127.0.0.1', 'port' => '80', 'headers' => {'X-Foo' => 'Bar'}})
   #
   def create_aca_client(c)
     required_config_keys = 'aca', 'ua_string', 'port', 'headers', 'mode'
     raise "nil configuration is invalid for client factory" if (c == nil)

     #If input is a string assume it is a prototype
     if (c.class == String)
       c = {'prototype' => c}
     end

     #If we have a prototype configuration for either the prototype or aca
     #Use that to obtain default values for aca,port,headers,ua_string,mode
     prototype = (c['prototype'] == nil) ? c['aca'] : c['prototype']
     prototype_config = @config[prototype]
     if (prototype_config)
       #puts ">>>PROTOTYPE CONFIG:" + YAML::dump(prototype_config)
       c['aca'] ||= prototype
       c['port'] ||= prototype_config['port']
       c['headers'] ||= prototype_config['headers']
       c['ua_string'] ||= prototype_config['ua_string']
       c['mode'] ||= prototype_config['mode']
     end

     #Make sure we have all of the configuration for the Aca Client
     required_config_keys.each do |k|
       raise "AcaClient #{k} cannot be nil " + YAML::dump(c) unless (c[k] != nil)
     end

     #Return a new client
     return AcaClient.new(c['aca'],c['port'],c['headers'],c['ua_string'],c['mode'])
   end #create_aca_client
end
