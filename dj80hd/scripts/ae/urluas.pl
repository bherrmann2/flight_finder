use DBI;
use URI;
use LWP;
use Getopt::Std;

#
#
# Date
# 02-JAN-2009 jwerwath   Add ability to output an .html file
# 05-JAN-2009 jwerwath   Add unit tests.
#
$USAGE_URL = 'http://scissorsoft.com/ae/aardvark_extreme.php';
$PAIRS_TEMPLATE_TAG = "___INSERT_PAIRS_HERE___";
$USAGE = <<END_USAGE;
$BLOCKSIZE = 50;



flag name                description
---- ------------------- ------------------------------------------------------
-c   customer_code       database code for customer (turkcell|vfuk|vzw|uscc|.)

-y   year of data        Year of data to be searched in db (e.g. 2008)       

-m   month of data       Month of data to be searched in db (e.g. 11 = NOV)            

-k   pornkeywords file   text file of newline seperated porn keywords
                         (Optional, but requires porndomains (-d) parameter

-d   porndomains file    text file of newline seperated porn domain names
                         (Optional; Porn will not be filtered when absent)   

-o   output_file         All url/ua pairs will be written to this file.
                         If the filename is .txt only the pairs will be written.
                         If the filename is .html, an html file will be written.
                         This html file is a full interface to screen and upload the URLs.

-l   limit               The number of url/ua pairs to request from database.  
                         Note that the results will be less as urls are checked
                         for validity and (optionally) for porn

-u   backend_url         Specifying this option will have url/ua posted to NOAR

-h   help                print this message

-t   test                Run Unit Tests.


Examples:
---------
perl $0 -c vzw -l 200 -y 2008 -m 11 -o foo.txt -k pornkeywords.txt -d porndomains.txt
Gets 200 random url/ua combinations from the VFUK logs of November year 2008 
and writes them to foo.txt

Notes:
1. Upadating Porn Domains File:
   ----------------------------

2. 

END_USAGE

my %args;
getopt('c:y:k:u:d:o:m:l:ht',\%args);
my $year = $args{y};
my $customer_code = $args{c};
my $month = $args{m};
my $order = " order by rand()";
my $limit = $args{l};
my $outfile = $args{o};
my $backend_url = $args{u};
my $pornkeywords_file = $args{k};
my $porndomains_file = $args{d};
my %porndomains;
my @pornkeywords;
#
#
if ($args{t}) {
  run_unit_tests();
  exit;
}
# Check Params
# If we got the help flag or if any passed parameters are null
# Print the USAGE help and die.
#
if ((!$year || !$customer_code || !$month || !$outfile || !$limit) || $args{h}) {
  print $USAGE;
  exit;
}

#
# make sure the output file is what we expect 
#
if (! (($outfile =~ /\.txt$/) || ($outfile =~ /\.html/))) {
  print "ERROR: The output file must be a .txt or .html filename\n";
  exit;
}

#
# Create the porn filter
#
create_porn_filter($porndomains_file,$pornkeywords_file);

my $end_query = $order . " limit " . $limit;
my $date = sprintf("%04d%02d",$year,$month);
my $url_q = "select distinct url from " . $customer_code . "_reports." . $customer_code . "_urls_" . $date . $end_query;
#$end_query = " order by rand() limit 100";
my $ua_q = "select distinct user_agent from " . $customer_code . "_reports." . $customer_code . "_uas_" . $date . $end_query; 
$ua_q = "select distinct user_agent from " . $customer_code . "_reports." . $customer_code . "_uas_" . $date;

my $user = 'jwerwath';
my $pass = 'BazUFrAy4k';
my $dbname = 'DBI:mysqlPP:working';
my $dbhost = '64.27.165.114';
my $dbport = '3306';              
my $dbstring = $dbname . ":" . $dbhost . ":" . $dbport;
my $dbh;
my $rows;
my $query;
my @urls = ();
my @uas = ();

#
# Connect to DB, exit on error
#
#report("Connecting to $dbstring as $user");
#$dbh = DBI->connect($dbstring,$user,$pass);
#die "Could not get connection to $dbstring for $user " unless ($dbh);
#
##
## Query to get all the urls in @urls
##
#$query = $url_q;
#report("QUERY: $query");
#$rows = $dbh->selectall_arrayref($query);
#report("Done.");
#foreach $row (@$rows) {push @urls,$row->[0];}

#$rows = get_rows($url_q);
#foreach $row (@$rows) {push @urls,$row->[0];}
#
@urls = query2array($url_q);
@uas = query2array($ua_q);
#
##
## Query to get all the uas in @uas   
##
#$query = $ua_q;
#report("QUERY: $query");
#$rows = $dbh->selectall_arrayref($query);
#report("Done.");
#foreach $row (@$rows) {push @uas,$row->[0];}

#$rows = get_rows($ua_q);
#foreach $row (@$rows) {push @uas,$row->[0];}

#
# Create a list of url/ua pairs in @pairs
#
my @pairs = ();
foreach my $url (@urls) {
  push @pairs, add_http_if_needed($url) . "|" . $uas[rand @uas];
}


#write_string_as_file($out,$outfile) || die "Could not open $outfile for write.";
#report ("Unfiltered Results are in $outfile");
my @filtered_pairs = ();
if ($porndomains_file) {
  report ("Now applying filter...");
  my $i = 0;
  for ($i=0;$i<=$#pairs;$i++) {
    my $pair = $pairs[$i];
    if (pair_ok($pair)) {
      push @filtered_pairs,$pair;
      report("[OK " . $i . "/" . $#pairs . "]" . $pair); 
    }
    else {
      report("[SKIP " . $i . "/" . $#pairs . "]" . $pair); 
    }
  }
  report ("Done Filtering.");
}
else {
  @filtered_pairs = @pairs;
  report ("Filtering Skiped.");
}

$file_contents = get_file_contents($outfile,@filtered_pairs);
write_string_as_file($file_contents,$outfile) || die "Could not open $outfile for write.";
report ("Results are in $outfile");

if ($backend_url) {
  report ("Posting data to $backend_url");
  send_data_to_backend(join("\n",@pairs));
  report ("Done.");
}


sub query2array { #($query)
  my $query = shift;
  my @ret = ();
  report("Connecting to $dbstring as $user");
  my $dbh = DBI->connect($dbstring,$user,$pass);
  die "Could not get connection to $dbstring for $user " unless ($dbh);
  report("QUERY: $query");
  my $sth = $dbh->prepare($query);
  $sth->execute or die $DBI::errstr;
  while (my @row = $sth->fetchrow_array()) {
    push @ret,$row[0];
  }
  $sth->finish;
  $dbh->disconnect if ($dbh);
  report("Query Complete. Connection Closed.");
  return @ret;   
}

sub get_rows { #($query)
  my $query = shift;
  report("Connecting to $dbstring as $user");
  my $dbh = DBI->connect($dbstring,$user,$pass);
  die "Could not get connection to $dbstring for $user " unless ($dbh);
  report("QUERY: $query");
  my $rows = $dbh->selectall_arrayref($query);
  $dbh->disconnect if ($dbh);
  report("Query Complete. Connection Closed.");
  return $rows;
        
}
sub create_porn_filter { #($porndomains_file,$pornkeywords_file)
  my $porndomains_file = shift;
  my $pornkeywords_file = shift;
  if ($porndomains_file) {
    report("Creating Porn filter...");
    open(F,$porndomains_file) || die "Could not open '" . $porndomains_file . "'"; 
    foreach (<F>) {
      chomp;
      $porndomains{$_} = 1  ;
    }
    report("Done.");
    close F  ;

    # If there are porn keywords specified, add those.
    if ($pornkeywords_file) {
      if (open(F,$pornkeywords_file)) { #|| die "Could not open '" . $PORN_DOMAINS_FILENAME . "'"; 
        foreach (<F>) {
          chomp;
          #Add keyword if first char is wcord char (e.g. ingore #, whitespace, etc.)
          push @pornkeywords,$_ unless (!/^\w/);
        }
        close F;
        report("Filtering keywords " . join(",",@pornkeywords));
      }
    }
  }
}
#
# Inspects the output file name and gets html or txt
# contents for that file depending on the extention
#
sub get_file_contents { #($outfile,@filtered_pairs)
  my $outfile = shift;
  my @pairs = @_;
  if ($outfile =~ /\.html$/) {
    return get_html_from_pairs(@pairs);
  }
  else {
    return join("\n",@pairs);
  }
} #get_file_contents


sub write_string_as_file {
  my ($string,$filename) = @_;
  if (open(F,">$filename")) {
    print F $string;
    close F;
    return 1;
  }
  return 0;
}

#
# Makes sure the pair is in the correct format and 
# checks the host in the url to make sure it is not porn
#
sub pair_ok {
  my $pair = shift;
  my ($url,$ua) = split(/\|/,$pair);
  $url =~ s/http:\/\///;
  $url =~ s/https:\/\///;
  $ua =~ s/\n//;
	my ($host,$rest) = split(/\//,$url); #get_host($url);
  if ($url && $ua && isRealUrl($url) && url_ok($host)) {
     return 1;
  }
  return 0;
}#pair_ok           

#
# Any url-ua combinations kept in the %urluas_to_add map are sent to the
# backend using the $backend_url, and $customer_code variables.
# The %urluas_to_add variable is then cleared.
#
sub send_data_to_backend {
  my $data = shift;
  http_post_data_to_backend($backend_url,$customer_code,$data);
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
  $url = add_http_if_needed($url);

  if (is_porn_url($url)) {
    report("[PORN URL] $url $code $content_type $content_length $len");
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
    report("[PORN CONTENT] $url has [" . join(",",@porn_matches ) . "]");
    return 0;
  }
  my $len = length($content);
  if ( ($code == 200) && ($content_type =~ /html/) && ($len >= 256)) {
    #print $resp->status_line;
    report("[*OK*] $url");
    return 1; 
  }
  else {
    report("[FAIL] $url $code $content_type $content_length $len");
    return 0; 
  }
}#sub url_ok

sub get_url_content {#($url)
  my $url = shift;                       
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
  return $content;
}

sub report {#($msg)
  my $msg = shift;
  print time() . ": " . $msg . "\n";
}

#
# This routine posts data for a given customer code to the aardvark extreme
# backend per the interface described in the comments.
# FIXME - What happens with a timeout/wrong URL, etc. ?
sub http_post_data_to_backend { #($customer_code,$data)
  my $ua = new LWP::UserAgent;
  my ($backend_url,$customer_code,$data) = @_;    
  my $resp = $ua->post($backend_url, 
           [ 'code' => $customer_code,
             'action' => 'add_data',
             'data' => $data
           ],
           );
  $content = ($resp) ? $resp->content : "null";
  if ($resp->code == 200 && $resp->content =~ /Success/) {
    print "============== Entries successfully added. ========\n$content";
  }
  else {
    print "============== ERROR ADDING ENTRIES:" . $resp->code . "=======\n$content";
  }       
}

#
# Appends a line to a file
#
sub append_to_file { #($filename,$line)
  my ($filename,$line) = @_;
  chomp($line);
  $line = $line . "\n";
  $file_string = (-e $filename) ? ">>$filename" : ">$filename";
  open(F,$file_string) or die "Could not open file $file_string";
  print F $line;
  close F;
}

#
# Returns true if the given string looks like a url, false otherwise
#
sub isRealUrl { #($string)
  my $url = shift;
    return !(
    ($url =~ /https:\/\//) || ($url =~ /htdocs/)
    ||  ($url =~ /startPg/) || ($url =~ /doubleclick/)
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

#
# Extract the root host portion of a URL.  The protocol is not included.
#
# e.g.  http://dj80hd.blogspot.com/2009/01/hacks-free-and-simple-mp3.html
#
# returns blogspot.com
#
sub get_host { #($url)
  my $url = add_http_if_needed(shift);
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

#
# Returns an array of all the porn keywords found in 
# the given content
#
sub find_porn_keywords { #($content)
  my $content = shift;
  my @lines = split(/\n/,$content);
  my @ret = ();
  my $regex = "(" . join("|",@pornkeywords) . ")";
  #print ">>>REGEX: $regex\n";
  my $no_lines_content = $content;
  $no_lines_content =~ s/[\r\n]//gm;
  @url_matches = ($no_lines_content   =~ /http:\/\/(\S+)/g );
  @meta_matches = ($no_lines_content  =~ /<meta ([^>]+)/g );
  @title_matches = ($no_lines_content =~ /<title>([^<]+)/g );
  #print ">>>" . join("<<<>>>",@url_matches,@meta_matches,@title_matches);
  foreach my $url (@url_matches) {
    my @matches = ($url =~ /$regex/gi);
    foreach my $url_match (@matches) {
      push @ret,$url_match . "(url)";
    }
  }
  foreach my $title (@title_matches) {
    my @matches = ($title =~ /$regex/gi);
    foreach my $title_match (@matches) {
      push @ret,$title_match . "(title)";
    }
  }
  foreach my $meta (@meta_matches) {
    my @matches = ($meta =~ /$regex/gi);
    foreach my $meta_match (@matches) {
      push @ret,$meta_match . "(meta)";
    }
  }
  return @ret;
}#find_porn_keywords

#
# returns 1 (true) if the domain of the given url
# is found to be a porn domain 0 (false) otherwise
#
sub is_porn_url {
  my $url = shift;
  my $host = get_host($url);
  if ($porndomains{$host} == 1) {
    return 1;
  }
  else {
    foreach my $keyword (@pornkeywords) {
      if ($url =~ /$keyword/) {
        return true;
      }
    }
  }
  return 0;
}

#
# Given a filename, returns the lines of the file
# as an array
#
sub file_2_array {
  my $filename = shift;
  open(F,"$filename") || die("Could not open file for read '$filename'");
  my @lines = (<F>);
  close F;
  return @lines;
}

#
# Creates a file with the given content
#
sub string_2_file { #($string,$filname)
  my $string = shift;
  my $filename = shift;
  open(F,">$filename") || die("Could not open file for write '$filename'");
  print F $string;
  close F;
} #string2file

#
# Gets the html from a given set of URL/UA pairs
#
sub get_html_from_pairs {
  my @raw_pairs = @_;
  my @pairs = ();       
  foreach my $pair (@raw_pairs) {
    chomp($pair);
    if ($pair =~ /\w+/) {
      $pair = ($pair =~ /^http/) ? $pair : "http://" . $pair;
      push @pairs,$pair;
    }
  }
  $javascript_pairs = "\"" . join("\",0,\n\"",@pairs) . "\",0\n";
  my $template = get_template_html();
  $template =~ s/$PAIRS_TEMPLATE_TAG/$javascript_pairs/;
  return $template;
} #get_html_from_pairs

#
# This is a bit hacky, but this will read a template html file.
# 
sub get_template_html {
  my $file = shift;
  $file = "template.html" unless $file;
  open(F,$file) || die("Could not open template file '$file'");
  my $template = join('',(<F>));
  close F;
  die "The template file '$file' does not contain the string '$PAIRS_TEMPLATE_TAG'" unless ($template =~ /$PAIRS_TEMPLATE_TAG/m);
  return $template;
}

sub run_unit_tests {
  create_porn_filter("porndomains.txt","pornkeywords.txt");
  die "Test 1 Failed" if (!test_1());
  die "Test 2 Failed" if (!test_2());
  print "ALL OK !";
}
sub test_1 {
  return 1;
}
sub test_2 {
  my $content = get_url_content("http://scissorsoft.com/testcases/superporn.html");
  my @m = find_porn_keywords($content);
  #print join(",",@m);
  my $count = $#m;
  return (56 == $count);
}
#-------------------------------- MAIN -----------------------------------
#my %args;
#getopt('i:o:', \%args);
#my $output_file = $args{o};
#my $input_file = $args{i};
#
#$USAGE =<<END_USAGE;
#Usage: perl $0 -i <input_file> -o <output_file>
#e.g.   perl $0 -i url_ua_pairs.txt -o foo.html
#
#END_USAGE
#
#if (!$input_file || !$output_file) {
#  print $USAGE;
#  exit;
#}
#
#my @lines = file_2_array($input_file);
#print ">>>Read " . $#lines . " lines from file $input_file\n";
#my $html_content = get_html_from_pairs(@lines);
#print ">>>Generated Javascript.\n";
#print ">>>Writing this html:\n$html_content.\n";
#string_2_file($html_content,$output_file);
#print ">>>Done: output is $output_file\n";
