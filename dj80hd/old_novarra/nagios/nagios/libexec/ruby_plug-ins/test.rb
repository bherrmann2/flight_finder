require 'rubygems'
require 'active_support'
require 'test/unit'
require 'net/http' 
require 'uri'
require 'yaml'
require 'fileutils'
require 'aca_client'
require 'video_check'
#
#
#

class TestAcaClient < Test::Unit::TestCase

  #
  # Before each test case is run, make sure the test ACA is running
  #
  def setup
  end

  def test_3hk        
    factory = AcaClientFactory.new
    c = factory.create_aca_client('3hk.proxy.novarra.com')
    r = c.load("http://www.youtube.com")
    assert_success(r, "aca=" + name)
    assert(r.http_content.include?('youtube'),"This did not include 'youtube':\n" + r.http_content)
  end

  def test_nagios_plugin(conf_file)
    nagios_plugin = VideoCheck.new
    nagios_plugin.check_all(conf_file)
    assert_equal(0,nagios_plugin.exit_code,nagios_plugin.exit_msg)
  end

  def test_uscc
    test_nagios_plugin('uscc_video_sites.conf')
  end
  def test_3hk
    test_nagios_plugin('3hk_video_sites.conf')
  end

  def test_vision9
    test_nagios_plugin('vision9.conf')
  end

  def assert_success(r,msg)
    msg = " " + msg
    assert(r != nil, "Response is NIL!" + msg)
    assert_equal(0,r.error_code,"error code " + r.error_code.to_s + msg)
    assert_equal(nil,r.error_msg,r.error_msg.to_s + msg)
    assert(r.resp != nil, "Response http resp is NIL!" + msg)
    assert(r.http_content != nil, "Response content is NIL!" + msg)
  end
end #class test AcaClient
