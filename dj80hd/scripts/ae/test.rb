require 'rubygems'
require 'active_support'
require 'test/unit'
require 'net/http' 
require 'uri'
require 'yaml'
require 'fileutils'
#
#
#

class TestAe < Test::Unit::TestCase

  @@test_url = "http://scissorsoft.com/ae_test/aardvark_extreme.php"

  #
  # For some tests, a stubbed out ACA (see TestAca class in test_aca file)
  #

  
  #
  # Before each test case is run, make sure the test ACA is running
  #
  def setup
  end

  def test_test
    get_content("?action=dump_as_yaml")
    assert (1 == 1)
  end

  def test_add_entries
    clear_database
    e = get_entries_as_yaml
    assert(e == nil,"entries should be nil but is " + e.to_s)


    text = <<END_ENTRIES
http://www.bigtitportal.com|LG-CU400/V1.0 Obigo/Q04C Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Link/6.3.0.0.0
http://mycounter.tinycounter.com|BlackBerry7130e/4.1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/104
http://88.214.227.83|Nokia6133/2.0 (05.60) Profile/MIDP-2.0 Configuration/CLDC-1.1
http://www.wannawatch.com|SAMSUNG-SGH-A707/1.0 SHP/VPP/R5 NetFront/3.3 SMM-MMS/1.2.0 profile/MIDP-2.0 
END_ENTRIES
    
    resp = postit(@@test_url,{'action' => 'add_data', 'code' => 'vfuk', 'data' => text})
    assert_equal('200',resp.code)
    assert(resp.body != nil)
    assert(resp.body.include?('Success'),"Not a success response")
    e = get_entries_as_yaml
    assert(e != nil,"Got no entries") 
    assert_equal(4,e.keys.size)

    #Make sure we get the entries in order.
    xml = get_entries_as_xml('vfuk',1)
    expected = "<?xmlversion=\"1.0\"?><traffic><hit><url>http://www.bigtitportal.com</url><useragent>LG-CU400/V1.0Obigo/Q04CProfile/MIDP-2.0Configuration/CLDC-1.1UP.Link/6.3.0.0.0</useragent><host>f73.novarra.net</host></hit></traffic>"
    assert_equal(expected,xml.gsub(/\s+/,''))
   
    #And make sure they are deleted. 
    e = get_entries_as_yaml
    assert(e != nil,"Got no entries")
    assert_equal(3,e.keys.size)

    #What happens if we get more than what is left ?
    xml = get_entries_as_xml('vfuk',4)
    expected = " <?xml version=\"1.0\"?> <traffic> <hit> <url>http://mycounter.tinycounter.com</url> <useragent>BlackBerry7130e/4.1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ven dorID/104</useragent> <host>f73.novarra.net</host> </hit> <hit> <url>http://88.214.227.83</url> <useragent>Nokia6133/2.0 (05.60) Profile/MIDP-2.0 Configuration/CLDC-1.1</us eragent> <host>f73.novarra.net</host> </hit> <hit> <url>http://www.wannawatch.com</url> <useragent>SAMSUNG-SGH-A707/1.0 SHP/VPP/R5 NetFront/3.3 SMM-MMS/1.2.0 profil e/MIDP-2.0 </useragent> <host>f73.novarra.net</host> </hit> </traffic>"
    assert_equal(expected.gsub(/\s+/,''),xml.gsub(/\s+/,''))

    xml = get_entries_as_xml('vfuk',4)
    expected = " <?xml version=\"1.0\"?><traffic></traffic>"
    assert_equal(expected.gsub(/\s+/,''),xml.gsub(/\s+/,''))
   
    #Add one more but this time for turkcell 
    e1_text = "http://www.bigtitportal.com|LG-CU400/V1.0 Obigo/Q04C Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Link/6.3.0.0.0"
    resp = postit(@@test_url,{'action' => 'add_data', 'code' => 'turkcell', 'data' => e1_text})
    assert_equal('200',resp.code)
    assert(resp.body != nil)
    assert(resp.body.include?('Success'),"Not a success response")
    e = get_entries_as_yaml
    assert(e != nil,"Got no entries")
    assert_equal(1,e.keys.size)
    e = get_entries_as_yaml('vfuk')
    assert(e == nil,"e should not be " + e.to_s)
    e = get_entries_as_yaml('any')
    assert(e != nil,"Got no entries")
    assert_equal(1,e.keys.size)


  end

  def test_add_garbage
    resp = postit(@@test_url,{'action' => 'add_data', 'code' => 'vfuk', 'data' => "bunch_of_bullshit"})
    assert_equal('601',resp.code,"BODY is " + resp.body)
  end

  def test_ie_voyeur

    #Success case
    url = @@test_url + "?action=get_next&type=ie"
    body = get_response_body(url)
    assert(!body.include?('AE_ERROR'),"This contains 'ERROR':\n" + body)
    #Error   case
    url = @@test_url + "?action=get_next"
    body = get_response_body(url)
    assert(body.include?('AE_ERROR'),"This does not contain 'ERROR':\n" + body)
  end


  #
  # =======================  Utility Functions =================
  #
  def get_entries_as_xml(code,count = 1)
          #http://scissorsoft.com/ae_test/aardvark_extreme.php?action=get_next&type=aardvark&cust=vfuk&count=1
    url = @@test_url + "?action=get_next&type=aardvark&cust=" + code + "&count=" + count.to_s
    return get_response_body(url)
  end


  def clear_database
    postit(@@test_url, {'action' => 'Clear Database', 'secret' => 'kerry4'})
  end
  def get_content(query_string = "") 
    body = get_response_body(@@test_url + query_string)
    return YAML.load(body)
  end

  def get_response_body(url)
    resp = Net::HTTP.get_response(URI.parse(url))
    if (resp == nil) 
      return nil          
    end
    return resp.body
  end

  # Post a hash of query data to a url
  def postit(url,hash)
    return Net::HTTP.post_form(URI.parse(url),hash)
    #Check response code!
  end

  def get_entries_as_yaml(cust = 'any')
    return get_content("?action=dump_as_yaml&cust=" + cust)
  end

  
end
