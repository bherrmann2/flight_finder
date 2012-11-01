#!perl

use URI;
#
# =========================== OVERVIEW ====================================
# This script scrapes unified logs and sends a periodic update to 
# Aardvark Extreme Backend.
#
# =========================== HISTORY =====================================
# 10-SEP-2008 jwerwath   Created.                                 
# 23-SEP-2008 jwerwath   Get log from STDIN
# 23-SEP-2008 jwerwath   Do not process dups.
# 29-SEP-2008 jwerwath   Changes for 3HK log - handle hosts w/o http://
# 02-OCT-2008 jwerwath   Imporve the performance of Porn Check 
# 03-OCT-2008 jwerwath   Read input files and streams only one line at a time.
# 05-DEC-2008 jwerwath   Allow the porn keywords
#
#
#
# ============== AARDVARK EXTREME INTERFACE ===============================
# new data for Aardvark extreme has the following form    
#
#      FORMAT: HTTP post with parameters
#      1. code = (3it | 3hk | vfuk | turkcell ... etc.)
#      2. action = add_data
#      3. data = A newline seperated lists of url-ua pairs where the url-ua
#                is seperated by a | like this...                      
#      ...
#      http://mycounter.tinycounter.com|BlackBerry7130e/4.1.0
#      http://88.214.227.83|Nokia6133/2.0 (05.60) Profile/MIDP-2.0 CLDC-1.1
#      ...
#
#      4. For a successful response we expect an HTTP 200 and the word
#         'Success' in the body of the response.  Any other response is to
#         be considered an error and the body of the message will be an 
#         explination of the error.
#
# ===== UNIFIED LOG FORMATS =====
# The following documentation is for the unified log format:
#
##"09 Jun 2006 00:00:25,044","ANLHR3-RACK-15/172.24.0.212","ACA-5","1149807259186","Novarra/5.1.137o(J2ME-OPT)","J2ME","172.24.0.21","213.161.90.203:8827","/","Submit","154","200","20041","304","","2","200","5","X-H3G-MSISDN=393486121867"
#
#Another example:
#21:29:15,112","IXLON01-RACK-74/172.17.0.74","ACA-0","BaH0o7eYNkaObV91nqjCZLccn0SNe5ikhnMEr0W3LzM_","Nokia6300/2.0 (05.50) Profile/MIDP-2.0 Configuration/CLDC-1.1","PHONE_WAP_20","212.252.234.175","http://htdocs","/images/icons/32/footer.png","Load","","200","522","7","0","2","999","","","0","image/png","t","I","","","1"
#These fields are defined in com.novarra.oamp.lmm.UnifiedLoggingPatternLayout and com.novarra.oamp.lmm.UnifiedLoggingPatternParser. They are described as follows:
#
#  1  ACCESSTIME                 09 Jun 2006 00:00:25,044
#  2  GEN_HOST                   ANLHR3-RACK-15/172.24.0.212
#  3  GEN_ACA                    ACA-5
#  4  DEVICEID                   1149807259186
#  5  USER_AGENT                 Novarra/5.1.137o(J2ME-OPT)
#  6  DEVICE_TYPE                J2ME
#  7  IP_ADDRESS                 172.24.0.21
#  8  HOST                       213.161.90.203:8827
#  9  TARGET                     /
# 10  EVENT                      Submit
# 11  NODE_ID                    154
# 12  STATUS_CODE                200
# 13  CONTENT_SIZE               20041
# 14  PROCESSING_TIME            304
# 15  BODY                       ""
# 16  CLASS_OF_SERVICE           2
# 17  CONTENT_SERVER_STATUS_CODE 200
# 18  LOAD_BALANCING_COOKIE      5
# 19  LOGGING_HEADER             X-H3G-MSISDN=393486121867
#                                x-bearer-id=GSM;APN-id=vodafonelive
# 20  IO_TIME                    4417 
#                                5869,2023
# 21  CONTENT_TYPE               text/html; charset=UTF-8
# 22  TXCODING_OPTIN             t                               user wants content transcoded, VF-UK
#                                f                               user wants PC-friendly content, VF-UK
# 23  TXCODING_STATUS            tx                              transcoded, VF-UK
#                                na                              not applicable
#                                pt                              passthru
#
#===== INCLUDES ======
use LWP;

#===== GLOBALS ======
$PORN_DOMAINS_FILENAME = 'porndomains.txt';
$PORN_KEYWORDS_FILENAME = 'pornkeywords.txt';

#Stores the porn domains as keys of a hash.  This way of looking them up will be
#quicker than string compares.
%PORN_DOMAINS = ();                               
@PORN_KEYWORDS = ();

#What to print for a help page.
$USAGE_URL = 'http://scissorsoft.com/ae/aardvark_extreme.php';
$USAGE = <<END_USAGE;
This script will taking an existing unified log file and extract urls and ua 
values to add to the aardvark extreme backend.

USAGE: perl $0 <customer_code> <ae_backend_url> <allow_porn> [<input_file>]

       Parameters
       ----------
       customer_code:  (vfuk|3it|3hk|turkcell|tim|wind|usc|eetg|)
                       A code representing the customer from which the log came
       ae_backend_url: url for the aardvark_extreme backend which      
                       manages all of the data.
       allow_porn:     yes | no - indicates if porn urls will be allowed
                       NOTE: if 'no', a file named 'porndomains.txt' is expected
                       to exist in the same directory as this script.
       intput_file:    (optional) will read log from this file, if not provided
                       STDIN will be used.


Example:                                                        
perl $0 vfuk $USAGE_URL yes < mylog.txt

Note: if the log is gziped on a a unix platform the following example is a handy
way to run the command:

gunzip < turkcell.log.gz | perl $0 turkcell $USAGE_URL yes

To see if the updates are made you can use the admin function of the backend
application.  For the above example this would be 
$USAGE_URL?action=admin

END_USAGE


#The number of url-ua combinations to collect before posting them to the 
#aardvark_extreme backend.
$BLOCKSIZE = 50;

#The default URL of the aardvark_extreme backend.
$AE_URL = "http://scissorsoft.com/ae/aardvark_extreme.php";





if ($#ARGV < 2)
{
  print $USAGE . "\n";
  exit;
}  

#Get all of our parameters
$customer_code = $ARGV[0];
$ae_backend_url = $ARGV[1];
$FILTER_PORN = ($ARGV[2] eq 'no');
$INPUT_FILENAME = $ARGV[3];

#Read in the Porn Domains if we need to filter.
if ($FILTER_PORN ) {
  report_to_stdout("Creating Porn filter...");
  open(F,$PORN_DOMAINS_FILENAME) || die "Could not open '" . $PORN_DOMAINS_FILENAME . "'"; 
  foreach (<F>) {
    chomp;
    $PORN_DOMAINS{$_} = 1;
  }
  close F;
  if (open(F,$PORN_KEYWORDS_FILENAME)) { #|| die "Could not open '" . $PORN_DOMAINS_FILENAME . "'"; 
    foreach (<F>) {
      chomp;
      #Add keyword if first char is word char (e.g. ingore #, whitespace, etc.)
      push @PORN_KEYWORDS,$_ unless (!/^\w/);
    }
    close F;
    report_to_stdout("Filtering keywords " . join(",",@PORN_KEYWORDS));
  }
  else {
    report_to_stdout("Warning $PORN_KEYWORDS_FILENAME was not found.");
  }
}
report_to_stdout("Porn filter created.");

#This url to ua map will hold URL/UA combinations we find in the log
%urluas_to_add = ();

#Record of hosts we have seen to avoid dups and needless rechecks.
%hosts_seen    = ();

if ($INPUT_FILENAME) {
  open (F,$INPUT_FILENAME) || die "Could not open file $INPUT_FILENAME";
  while (defined ($line =<F>) ) {
	  chomp($line);
    process_line($line);
  }
}
else { #No input file specified so use STDIN
  while (defined ($line = <STDIN>)) {
	  chomp($line);
    process_line($line);
  }
}

#Add any ones we have left:
send_data_to_backend();

sub process_line {
  my $line = shift;
	$len = length($line);
	#Remove begin and end quotes from the log file line
  $line = substr($line,1,($len - 2));
	#Split unified log into its parts
	@parts = split("\",\"",$line);

	if ($#parts < 10)
	{
		die "ERROR the following log file line is not EXPECTED: " . $line;
	}

  #Combine the host and target to form the URL, and get the UA
	$host = add_http_if_needed($parts[7]);
	$url = $host . $parts[8];
  $ua = $parts[4];

  #Now check the URL / UA combination and add it to the list if it is ok.
  if ($url && $ua) {
    #If it is a real URL that we have not yet seen...
    if (isRealUrl($url) && ! $urluas_to_add{$parts[7]}){
      #If this URL still produces expected content...
      if (url_ok($host)) {
        #Add it to the list.
        $urluas_to_add{$host} = $ua;

        #Get the count of how many we now have in our list.
        my $count = scalar keys %urluas_to_add;
        #Give some feedback to the user on where we are at and what we found
        report_to_stdout("[#" . $count . "] $host" . "|" . $ua . "\n");

        #If we have collected enough to send...
        if ($count >= $BLOCKSIZE) {
          send_data_to_backend();
        }
      }
      $hosts_seen{$host} = 1; #Mark that we have dealt with this host
    }
    else {#Ignore this url, it is not valid or we have processed it already.
    }
  }
  else {#Ignore this url/ua combination - it appears invalid.
  }
}#process_line

#
# Any url-ua combinations kept in the %urluas_to_add map are sent to the
# backend using the $ae_backend_url, and $customer_code variables.
# The %urluas_to_add variable is then cleared.
#
sub send_data_to_backend {
  #Access globals %urluas_to_add
  my $data = "";
  foreach (keys(%urluas_to_add)) {
    $data .= $_ . "|" . $urluas_to_add{$_} . "\n";
  }
  chomp($data);

  #2. Send it to the backend
  #print "====Sending this data for $customer_code via $ae_backend_url ====\n$data";
  http_post_data_to_backend($ae_backend_url,$customer_code,$data);
  
  #3. Reset our list of data to add.
  %urluas_to_add = ();
}#send_data 


sub add_http_if_needed {#($url) 
  my $url = shift;
  return ($url =~ /http:/) ? $url : "http://" . $url;
}
#
# See if an array contains an element.
#
sub array_contains {#$needle,@haystack
  my $needle, @haystack = @_;
  undef %seen;
  for (@haystack) {$seen{$_} = 1;}
  return $seen{$needle};
}

#
# Check that a given URL still produces real html content
# A url is considered valid if it produces an HTTP 200 with at least
# 256 bytes of html within 10 seconds.
#
# Returns 1 (true) if ok, 0 (false) if not.
#
sub url_ok {
  my $url = shift;

  if ($hosts_seen{$url}) {
    report_to_stdout("[DUP ] $url $code $content_type $content_length $len");
    return 0; 
  }
  if ($FILTER_PORN && is_porn_url($url)) {
    report_to_stdout("[PORN URL] $url $code $content_type $content_length $len");
    return 0; 
  }
  my $ua = LWP::UserAgent->new();
  $ua->agent("Mozilla/5.0 (Windows; U; Windows NT 5.2; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14");
  $ua->timeout(10);
  $resp = $ua->get($url,
          		  'User-Agent' => "Mozilla/5.0 (Windows; U; Windows NT 5.2; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14",
          'Accept' => "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
		  'x-wte-msisdn' => '666', 
		  );
  my $code = $resp->code;
  my $content_type = $resp->content_type;
  my $content = $resp->content;
  my @porn_matches = find_porn_keywords($content);
  if (@porn_matches) {
    report_to_stdout("[PORN CONTENT] $url has [" . join(",",@porn_matches ) . "]");
    return 0;
  }
  my $len = length($content);
  if ( ($code == 200) && ($content_type =~ /html/) && ($len >= 256)) {
    #print $resp->status_line;
    report_to_stdout("[*OK*] $url");
    return 1; 
  }
  else {
    report_to_stdout("[FAIL] $url $code $content_type $content_length $len");
    return 0; 
  }
}#sub url_ok

sub report_to_stdout {#($msg)
  my $msg = shift;
  print time() . ": " . $msg . "\n";
}

#
# This routine posts data for a given customer code to the aardvark extreme
# backend per the interface described in the comments.
# FIXME - What happens with a timeout/wrong URL, etc. ?
sub http_post_data_to_backend { #($customer_code,$data)
  my $ua = new LWP::UserAgent;
  my ($ae_backend_url,$customer_code,$data) = @_;    
  my $resp = $ua->post($ae_backend_url, 
           [ 'code' => $customer_code,
             'action' => 'add_data',
             'data' => $data
           ],
           );
  $content = ($resp) ? $resp->content : "null";
  if ($resp->code == 200 && $resp->content =~ /Success/) {
    print "============== $BLOCKSIZE entries successfully added. ========\n$content";
  }
  else {
    print "============== ERROR ADDING ENTRIES:" . $resp->code . "=======\n$content";
  }       
}
sub append_to_file { #($filename,$line)
  my ($filename,$line) = @_;
  chomp($line);
  $line = $line . "\n";
  $file_string = (-e $filename) ? ">>$filename" : ">$filename";
  open(F,$file_string) or die "Could not open file $file_string";
  print F $line;
  close F;
}

#sub get_host{ #url
#  my $url = shift;
#  $url =~ s/http:\/\///;
#  $url =~ s/https:\/\///;
#  return $url;
#}
#
# Checks if this is https, startpage, or ACA stuff.
#
sub isRealUrl {
  my $url = shift;
    return !(
    ($url =~ /https:\/\//) || ($url =~ /htdocs/)
    ||  ($url =~ /startPg/)
    );   
}#isRealUrl

#
# Returns true if this looks like an image url.
#
sub isImageUrl {
    my $url = shift;
    return (
        ($url =~ /\.jpg$/) || ($url =~ /\.JPG$/)
    ||  ($url =~ /\.jpeg$/) || ($url =~ /\.JPEG$/) || ($url =~ /\.Jpeg/)
    ||  ($url =~ /\.gif$/) || ($url =~ /\.GIF$/)
    ||  ($url =~ /\.swf$/) || ($url =~ /\.SWF$/)
    ||  ($url =~ /\.js$/) || ($url =~ /\.JS$/)
    ||  ($url =~ /\.png$/) || ($url =~ /\.PNG$/)
    ||  ($url =~ /\.bmp$/) || ($url =~ /\.BMP$/)
    ||  ($url =~ /startPg/)
    );  
}#isImageUrl
sub get_host {
  my $url = shift;
  my $uri = URI->new($url);
  my $host = $uri->host;
  my @parts = split(/\./,$host);
  if ($#parts >= 1) {
    my $last_part = $parts[$#parts];
    my $second_last_part = $parts[$#parts - 1];
    my $last_two_parts = $second_last_part . "." . $last_part;
    if (($last_part eq "uk") && ($second_last_part eq "co") && $#parts >= 2) {
      return $parts[$#parts -2] . "." . $last_two_parts; #e.g. bbc.co.uk
    }
    else {
      return $last_two_parts; #e.g. dj80hd.com
    }
  }
  else {
    return $host;
  }
}

sub find_porn_keywords { #($content)
  my $content = shift;
  my @lines = split(/\n/,$content);
  my @ret = ();
  my $regex = "(" . join("|",@PORN_KEYWORDS) . ")";
  #my @matches = ($content =~ /$regex/g);
  #if (@matches) {
  #  push @ret,@matches;
 #}
  #foreach my $keyword (@PORN_KEYWORDS) {
  #  if ($content =~ /$keyword/) {
  #    push @ret,$keyword;
  #  }
  #}
  foreach my $line (@lines) {
    if ($line =~ /<(meta|title)/i) {
      my $tag = $1;
      my @matches = ($line =~ /$regex/gi);
      foreach (@matches) {
        push @ret,$_ . "($tag)";
      }
    }
  }
  return @ret;
}#find_porn_keywords

sub is_porn_url {
  my $url = shift;
  my $host = get_host($url);
  if ($PORN_DOMAINS{$host} == 1) {
    return 1;
  }
  else {
    foreach my $keyword (@PORN_KEYWORDS) {
      if ($url =~ /$keyword/) {
        return true;
      }
    }
  }
  return 0;
}
