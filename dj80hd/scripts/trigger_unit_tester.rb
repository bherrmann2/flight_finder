#!ruby


#
# A TriggerTestSuit is a collection of Testcases that can be run with one
# call and will report all the results.
#
class TriggerTestSuite < Array
  def run
    pass = 0
    fail = 0
    details = ""
    self.each do |testcase|
      result = testcase.run
      (result == "") ? pass = pass + 1 : fail = fail + 1
      details += result
    end
    print details + "\n<<<<<PASS=#{pass} FAIL=#{fail}>>>>>\n";
  end
end #TriggerTestSuite


#
# A TriggerTestCase contains the following:
# - an input string
# - an expected output string
# - an expected return code
# - a string represending the STDOUT expected
# - directory to run the test case
# - the command line command that will actually run the test case
#
# FIXME - put example here
class TriggerTestCase

  #temp file name for content
  @@tmp_filename = "c:\\foo.txt"

  def initialize(name, input, expected_output, expected_retcode, expected_stdout, dir, cmd)
    #FIXME - Is there a way to get these names right from the parameter list ?
    params = ["name", "input", "expected_output","expected_retcode","expected_stdout","dir","cmd"]

    #Create an instance variable for each one and set it
    params.each {|p| eval("@" + p + " = " + p)}

    #FIXME - CHeck input !!!
  end #initialize

  #If test is ok, an empty string is returned, othewise an error message
  def run
    #Save this so we can get back here after running cmd in a different dir
    current_dir = Dir.pwd
    
    begin
      #1. Create the input file
      File.open(@@tmp_filename, 'w') {|f| f.write(@input) }
    
      #2. Change into the correct dir                           
      Dir.chdir(@dir) #FIXME - Check error on this ?

      #3. Run the command
      stdout = IO.popen(@cmd){|pipe| pipe.read}

      #4. check its stdout 
      return "[#{@name}]GOT STDOUT #{stdout} EXPECTED #{@expected_stdout}" unless (strings_equal?(stdout,@expected_stdout))

      #5. Check Return code
      return "[#{@name}]GOT RETCODE #{$?.exitstatus} EXPECTED #{@expected_retcode}" unless ($?.exitstatus == @expected_retcode)
      
      #6. re-read the input file to get the output.
      output = ""
      File.open(@@tmp_filename, 'r') {|f| output = f.read}
      return "[#{@name}]GOT OUTPUT #{output} EXPECTED #{@expected_output}" unless (output == @expected_output)
      
      return "" #SUCCESS IF WE GOT HERE
    rescue
      return "[#{@name}]EXCEPTION: " + $!
    ensure
      Dir.chdir(current_dir)
    end
  end

  def strings_equal?(expected,got)
    a = expected.strip
    b = got.strip
    return (a == b)
    #len = a.length
    #0.upto(len - 1) do |i|
    #  if (a[i] != b[i])
    #    print "\n\n\n\n\n\nMISMATCH AT #{i} (#{a[i]} vs #{b[i]})"
#	return false;
#      end
#    end
#    return true;
  end


  def to_string
     return "output is " + @expected_output;
  end #to_string
end

expected_stdout = <<EXPECTED_OUT
werwath
EXPECTED_OUT

expected_server_preop_trig_fail_stdout = <<EXPECTED_SERVER_PREOP_TRIG_FAIL_STDOUT
Only members of the build group can modify a _release stream
EXPECTED_SERVER_PREOP_TRIG_FAIL_STDOUT

expected_server_admin_trig_fail_stdout = <<EXPECTED_SERVER_ADMIN_TRIG_FAIL_STDOUT
Basing a new stream on existing stream 'brew_int' disallowed:
server_admin_trig: You are not in the Admin group.
EXPECTED_SERVER_ADMIN_TRIG_FAIL_STDOUT

server_preop_trig-promote_into_release_requires_build_group-fail_1 = <<SERVER_PREOP_TRIG_PROMOTE_INTO_RELEASE_REQUIRES_BUILD_GROUP_FAIL_1
<triggerInput>
  <hook>server_preop_trig</hook>
  <output_file>cache/0_0.out</output_file>
  <command>promote</command>
  <principal>jwerwath</principal>
  <ip>127.0.0.1</ip>
  <stream1>j2me_6.9.0.35.14_int</stream1>
  <stream2>j2me_6.9.0.35.14_release</stream2>
  <depot>root</depot>
  <fromClientPromote></fromClientPromote>
  <changePackagePromote></changePackagePromote>
  <comment>df</comment>
  <elemList>
    <elem>/midp/com/novarra/j2me/http/GZIPInputStream.java</elem>
  </elemList>
  <elements>
    <elem
        count="0"
        eid="8508"
        elemType="text"
        hierType="parallel">/midp/com/novarra/j2me/http/GZIPInputStream.java</elem>
  </elements>
</triggerInput>
SERVER_PREOP_TRIG_PROMOTE_INTO_RELEASE_REQUIRES_BUILD_GROUP_FAIL_1
server_preop_trig-promote_into_release_requires_build_group-pass_1 = <<SERVER_PREOP_TRIG_PROMOTE_INTO_RELEASE_REQUIRES_BUILD_GROUP_PASS_1
<triggerInput>
  <hook>server_preop_trig</hook>
  <output_file>cache/0_0.out</output_file>
  <command>promote</command>
  <principal>jwerwath</principal>
  <ip>127.0.0.1</ip>
  <stream1>j2me_6.9.0.35.14_code_review</stream1>
  <stream2>j2me_6.9.0.35.14_int</stream2>
  <depot>root</depot>
  <fromClientPromote></fromClientPromote>
  <changePackagePromote></changePackagePromote>
  <comment>df</comment>
  <elemList>
    <elem>/midp/com/novarra/j2me/http/GZIPInputStream.java</elem>
  </elemList>
  <elements>
    <elem
        count="0"
        eid="8508"
        elemType="text"
        hierType="parallel">/midp/com/novarra/j2me/http/GZIPInputStream.java</elem>
  </elements>
</triggerInput>
SERVER_PREOP_TRIG_PROMOTE_INTO_RELEASE_REQUIRES_BUILD_GROUP_PASS_1

server_preop_trig-promote_into_release_requires_build_group-pass_2 = <<SERVER_PREOP_TRIG_PROMOTE_INTO_RELEASE_REQUIRES_BUILD_GROUP_PASS_2
<triggerInput>
  <hook>server_preop_trig</hook>
  <output_file>cache/0_0.out</output_file>
  <command>promote</command>
  <principal>admin</principal>
  <ip>127.0.0.1</ip>
  <stream1>j2me_6.9.0.35.14_int</stream1>
  <stream2>j2me_6.9.0.35.14_release</stream2>
  <depot>root</depot>
  <fromClientPromote></fromClientPromote>
  <changePackagePromote></changePackagePromote>
  <comment>df</comment>
  <elemList>
    <elem>/midp/com/novarra/j2me/http/GZIPInputStream.java</elem>
  </elemList>
  <elements>
    <elem
        count="0"
        eid="8508"
        elemType="text"
        hierType="parallel">/midp/com/novarra/j2me/http/GZIPInputStream.java</elem>
  </elements>
</triggerInput>
SERVER_PREOP_TRIG_PROMOTE_INTO_RELEASE_REQUIRES_BUILD_GROUP_PASS_2

server_admin_trig-only_admin_creates_childs_streams_from_int_and_release-fail_1 <<SERVER_ADMIN_TRIG_ONLY_ADMIN_CREATES_CHILDS_STREAMS_FROM_INT_AND_RELEASE_FAIL_1
<triggerInput>
  <depot>root</depot>
  <hook>server_admin_trig</hook>
  <command>mkstream</command>
  <principal>jwerwath</principal>
  <ip>127.0.0.1</ip>
  <stream1>b2</stream1>
  <stream2>brew_int</stream2>
  <streamType>regular</streamType>
</triggerInput>
SERVER_ADMIN_TRIG_ONLY_ADMIN_CREATES_CHILDS_STREAMS_FROM_INT_AND_RELEASE_FAIL_1

server_admin_trig-only_admin_creates_childs_streams_from_int_and_release-fail_2 <<SERVER_ADMIN_TRIG_ONLY_ADMIN_CREATES_CHILDS_STREAMS_FROM_INT_AND_RELEASE_FAIL_2
<triggerInput>
  <depot>root</depot>
  <hook>server_admin_trig</hook>
  <command>mkstream</command>
  <principal>jwerwath</principal>
  <ip>127.0.0.1</ip>
  <stream1>b2</stream1>
  <stream2>brew_release</stream2>
  <streamType>regular</streamType>
</triggerInput>
SERVER_ADMIN_TRIG_ONLY_ADMIN_CREATES_CHILDS_STREAMS_FROM_INT_AND_RELEASE_FAIL_2


server_admin_trig-only_admin_creates_childs_streams_from_int_and_release-pass_1 <<SERVER_ADMIN_TRIG_ONLY_ADMIN_CREATES_CHILDS_STREAMS_FROM_INT_AND_RELEASE_PASS_1
<triggerInput>
  <depot>root</depot>
  <hook>server_admin_trig</hook>
  <command>mkstream</command>
  <principal>jwerwath</principal>
  <ip>127.0.0.1</ip>
  <stream1>b2</stream1>
  <stream2>brew_code_review</stream2>
  <streamType>regular</streamType>
</triggerInput>
SERVER_ADMIN_TRIG_ONLY_ADMIN_CREATES_CHILDS_STREAMS_FROM_INT_AND_RELEASE_PASS_1

input = "put this in a file"
server_preop_trig_dir = "c:\\Program Files\\AccurevTest\\storage\\depots\\root\\triggers";
server_preop_trig_bat= "server_preop_trig.bat";
server_admin_trig_dir = "c:\\Program Files\\AccurevTest\\storage\\site_slice\\triggers";
dir = "c:\\tmp\\virginia";
suite = TriggerTestSuite.new();

# Test cases for the serper preop trigger
input = server_preop_trig-promote_into_release_requires_build_group-pass_1
output = ""
stdout = "";
suite << TriggerTestCase.new("server_preop_trig pass 1",input,output,0,stdout,server_preop_trig_dir,server_preop_trig_bat)

input = server_preop_trig-promote_into_release_requires_build_group-pass_2
output = ""
stdout = "";
suite << TriggerTestCase.new("server_preop_trig pass 2",input,output,0,stdout,server_preop_trig_dir,server_preop_trig_bat)

input = server_preop_trig-promote_into_release_requires_build_group-fail_1
output = input
stdout = expected_server_preop_trig_fail_stdout
suite << TriggerTestCase.new("server_preop_trig fail 1",input,input,0,stdout,server_preop_trig_dir,server_preop_trig_bat)


input = server_admin_trig-only_admin_creates_childs_streams_from_int_and_release_fail_1
output = input
stdout = expected_server_admin_trig_fail_stdout
suite << TriggerTestCase.new("server_admiontrig fail 1",input,input,0,stdout,server_admin_trig_dir,server_admin_trig_bat)

input = server_admin_trig-only_admin_creates_childs_streams_from_int_and_release_fail_2
output = input
stdout = expected_server_admin_trig_fail_stdout
suite << TriggerTestCase.new("server_admin_trig fail 2",input,input,1,stdout,server_admin_trig_dir,server_admin_trig_bat)

input = server_admin_trig-only_admin_creates_childs_streams_from_int_and_release_pass_1
output = ""                  
stdout = ""                                          
suite << TriggerTestCase.new("server_admin_trig pass 1",input,input,0,stdout,server_admin_trig_dir,server_admin_trig_bat)


x = TriggerTestCase.new("server_preop_trig pass 1",input,input,0,stdout,server_preop_trig_dir,server_preop_trig_bat)
x = TriggerTestCase.new("test1",input,input,0,expected_stdout,dir,"whoami")
y = TriggerTestCase.new("test1",input,"failme",0,expected_stdout,dir,"whoami")
suite << y 
suite.run
