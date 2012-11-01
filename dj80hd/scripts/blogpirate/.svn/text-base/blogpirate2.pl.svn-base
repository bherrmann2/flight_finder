#!perl -w

#
# see USAGE below for information on how to get this
#
# 25-SEP-2009 Initial version based on blograpist.pl  Rewritten to not
#             use external cgi scripts.  All functionality is internal to
#             this script.
# 12-MAR-2011 Update to support box.net, use only one ua, one cookie jar
#

use strict;
use URI;
use URI::Escape;
use LWP::UserAgent;
use Getopt::Std;   
use HTTP::Date;         
use HTTP::Cookies;         
use HTTP::Request;         
use HTTP::Response;         
use HTTP::Headers;          
use URI::URL;
use MIME::Base64;

my $b = LWP::UserAgent->new();
$b->cookie_jar({});
$b->agent("Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)");
my $cookies = HTTP::Cookies->new;

my $SLEEP_TIME = 1;
#
# Get all our command line input into nice vars
my %o = ();
getopts("a:b:o:x:i:d:u:l:",\%o);
my $action = "none";
$action = $o{"a"};
my $blog = $o{"b"};
my $output_filename = $o{"o"};
my $url             = $o{"u"};
my $input_filename = $o{"i"};
my $ignore_filename = $o{"x"};
my $dir = $o{"d"};
my $url_list_file = $o{"l"};
$action = "none" unless $action;

if ("getlinks" eq $action) {
  my $location = ($blog) ? $blog : $url;
  $location = ($location) ? $location : $url_list_file;
  debug("Got location $location");
  if ($location ) {
    debug ("Getting links from location $location ...");
    my @links = getlinks($location,$output_filename);
    debug ("Got " . ($#links + 1) . " links:" . join("\n", @links));
    print join("\n",@links) unless ($output_filename);
  }
  else {
    usage();
  }
}
elsif ($action eq "download") {
  if ($dir) {

    if (! -e $dir) {
      print "THIS DIRECOTRY DOES NOT EXIST: $dir\n";
      exit 1;
    }
    #Download a list of mp3 links
    if ($input_filename) { 
      my @urls = filename2array($input_filename);
      download_links($dir,$ignore_filename,@urls);
    }
    #Scrape a list of urls and download all the mp3 links you find.
    elsif ($url_list_file) {
      if (-e $url_list_file) {
        my @sites= filename2array($url_list_file);
        my @urls = get_links_from_urls(@sites);
        download_links($dir,$ignore_filename,@urls);
      }
      else {
        print "ERROR: This file does not exist: '$url_list_file')\n";
      }
    }
    elsif ($url) {
      #Scrape this url for links.
      my @mp3_urls = get_links_from_url($url);
      download_links($dir,$ignore_filename,@mp3_urls);
    }
    else {
      usage();
    }
    
  }
  else {
    usage();
  }
}
elsif ($action eq "test") {
  usage() unless ($dir && $url);
  my @a = ($url);
  my $ignore_file;
  download_links($dir,$ignore_file,@a);
}
else {
  usage();
}
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub unescape {
    my($todecode) = @_;
    $todecode =~ tr/+/ /;    # pluses become spaces
    $todecode =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $todecode;
}

# Do a simple HTTP get on a url and return the HTTP::Response object 
sub get_resp {
  my $url = shift;
  my $resp = $b->get($url);
  return $resp;
}#get_resp

sub no_linebreaks {
  my $s = shift;
  $s =~ s/\n//gi;
  $s =~ s/\r//gi;
  return $s;
}

#Get the stuff between the <title></title> of a url
sub get_url_title {
  my $url = shift;
  my $resp = get_resp($url,$cookies);
  my $content = no_linebreaks($resp->content());
  if ($content =~ /<title>([^<]+)<\/title>/i) {
    my $title = trim($1);
    $title =~ s/&amp;/&/g;
    $title =~ s/&quot;/"/g;
    $title =~ s/\@//g;
    $title =~ s/\//\-/g;
    $title =~ s/\"//g;
    $title =~ s/\!//g;
    $title =~ s/\|//g;
    return $title;
  }
  else {
    debug("NO TITLE for $url");
  }
}#get_url_title


sub download_links {
  my $dir = shift;
  my $ignore_filename = shift;
  my @urls = @_;
  debug("INPUT URL COUNT: " . ($#urls + 1));
  if ($ignore_filename) {
    @urls = ignore_file($ignore_filename,@urls);                  
  }
  @urls = make_unique(@urls);
  debug("FILTERED  COUNT: " . ($#urls + 1));
  my $count = 0;
  my $error_count = 0;
  my @failedurls = ();

  foreach my $url (@urls) {
    debug("GETTING [$count/" . $#urls . " with " . $error_count . " errors]: $url");
    my $resp;
    my $filename;
    my $error;
    my $ct; 
    my $code;
    #FIXME - Make this more OO
    debug("RESPONSE SHOULD BE NULL") unless (!$resp);
    #e.g. http://www10.zippyshare.com/v/56979338/file.html
    if ($url =~ /zippyshare\.com/) {
      $resp = get_zippyshare_resp($url)
    }
    #e.g. http://www.zshare.net/audio/6607486487c5b1d1/
    elsif ($url =~ /zshare\.net/) {
      $resp = get_zshare_resp($url)
    }
    #e.g. http://www.box.net/shared/61cu3t3udj
    elsif ($url =~ /box\.net\/shared/) {
      $resp = get_box_resp($url)
    }
    #e.g. http://www.mediafire.com/?w2nyzzzgktg
    elsif ($url =~ /mediafire\.com/) {
      $resp = get_mediafire_resp($url)
    }
    elsif ($url =~ /sendspace\.com/) {
      $resp = get_sendspace_resp($url)
    }
    elsif ($url =~ /youtube\.com/) {
      $filename = get_url_title($url,{});
      $filename =~ s/\s+/_/gi;
      $filename = $filename . ".mp4";
      $resp = get_youtube_resp($url);
      $code = $resp->code();
      $ct = $resp->content_type();
      $error = "BAD YOUTUBE $code $ct" unless ($code == 200 && $ct eq "video/mp4");
      
    }
    else {
      $resp = $b->get($url);
    }
   
  
    if (!$error) {
      if ($resp) {
        $error = save_file($url,$resp,$dir,$filename);
      }
      else {
        $error = "no resp";
      }
    }
    if ($error)
    {
      push(@failedurls,$url);
      $error_count += 1;
    }
    my $msg = ($error) ? $error . "(" . $url . ")" : "OK (" . $url . ")";
    
    #let the user know what is going on...
    debug ($msg);

    #add this url to our list that we have processed.
    append2filename($ignore_filename,$url);

    #be polite to websites
    sleep $SLEEP_TIME;

    $count += 1;
  }#foreach 

  debug("FAILED URLS:\n" . join("\n",@failedurls)) unless ($#failedurls<0);
  if (open(FAILED,">>failed.txt")) {
    print FAILED join("\n",@failedurls);
    debug("CHECK failed.txt for details.");
    close FAILED;
  }
}#download_links

#
# kick-off routine for the download process
#
# FIXME- refactor and make this make more sense.
#
sub download {
  my ($input_filename,$dir,$ignore_filename) = @_;
  my @urls = filename2array($input_filename);
  download_links($dir,$ignore_filename,@urls);
}#download


#
# $location - can be either a url or a file containing a list of urls
#             can also be the name of a blogspot blog
# $output_filename - the file name where the list of links is to be placed
#
# RETURNS: an array of all the links found in the url/file of urls/blog
#
sub getlinks {
  my ($location,$output_filename) = @_;
  my @links = ();
  #if this is a url
  if ($location =~ /http:\/\//) {
    @links = get_links_from_url($location);
  }
  #if this is a file, we will assume it is a list of urls
  elsif (-e $location) {
    my @urls = filename2array($location);
    @links = get_links_from_urls(@urls);
  }
  #else assume this is a blogspotblogname
  else {
    @links = all_links_on_blogspot_blog($location);
  }
  @links = make_unique(@links);
  array2filename($output_filename,@links) unless (!$output_filename);
  return @links;
}
  
#
# Takes as input
# - a filename of urls to ignore (format is newline sperated list of urls)
# - a list of urls to process
#
# A filtered list of urls is returned that do not exist in the file
#
sub ignore_file {
  my $ignore_filename = shift;
  my @links = @_;       
  return @links unless -e $ignore_filename;
  my @links_to_ignore = filename2array($ignore_filename);
  debug("FILTERING " . $#links_to_ignore . " URLS.");
  @links = make_unique(@links);
  @links_to_ignore = make_unique(@links_to_ignore);
  #debug("LINKS TO IGNORE:\n" . join("\n",@links_to_ignore));
  #debug("LINKS TO PROCESS:\n" . join("\n",@links));
  my %seen;
  foreach my $seen_url (@links_to_ignore) {
    $seen{$seen_url} = 1;
  }
  my @newlinks = ();
  foreach my $item (@links) {
    if ($seen{$item}) {
    }
    else {
      push (@newlinks,$item);
    }
  }
  return @newlinks;
} #ignore_file
  
sub make_unique {
  my @a = @_;
  my %seen = ();
  foreach my $item (@a) {
     $seen{$item}++;
  }
  return keys (%seen);
}


sub get_links_from_urls {
  my @urls = @_;
  my @a = ();
  foreach my $url (@urls) {
    my @links = get_links_from_url($url);
    foreach my $link (@links) {
      push @a,$link;
    } 
  }
  return @a;
}#get_links_from_urls


#
# Loads a url and extracts all the links that look like music files.
#
sub get_links_from_url {
  my @sample_urls = ();
  my $topurl = shift;
  if ($topurl =~ /http%3A%2F/) {
     $topurl = uri_unescape($topurl);
  }
  debug("Requesting content for $topurl");
  my $resp = $b->get($topurl);
  my $content = $resp->content();
  debug("Got resp content for $topurl");
  #debug($content);
  #debug("Got resp content for $topurl\n$content");
  my @hrefs = ();
  while ($content =~ m/href=\"(.*?)\"/gi) {push @hrefs,$1;}
  while ($content =~ m/<param name=\"src\" value=\"(.*?)\"/gi) {push @hrefs,$1;}
  while ($content =~ m/<param name=\"movie\" value=\"(.*?)\"/gi) {push @hrefs,$1;}
  while ($content =~ m/path=\"(.*?)\"/gi) {push @hrefs,$1;}
  while ($content =~ m/href=\'(.*?)\'/gi) {push @hrefs,$1;}
  while ($content =~ m/href=([-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)/gi) {push @hrefs,$1;}
  foreach my $href (@hrefs)
  {
  	my $abs = URI->new_abs($href,$topurl);
    
    #Handle crappy urls like 
    #http://www.noiseporn.com/audio/http://www.spreadthenoise.com/audio/jp/07%20Facemelter%20Live.mp3
    my $second_http = index($abs,"http://",1);
    if ($second_http > 0) {
       $abs = substr($abs,$second_http);
    }

  	#print "ABS=$abs\n";
  	#if ($abs =~ /\.wav|mp3$/)
    if ($abs =~ /^http:\/\/www\.zshare\.net\/download\/\S+/) {
  		push @sample_urls, $abs;
    }
    #elsif ($url =~ /box\.net\/shared/) {
    elsif ($abs =~ /^http:\/\/www\.zshare\.net\/audio\/(\S+)/) {
	  	push @sample_urls, "http://www.zshare.net/download/" . $1;
    }
    #elsif ($url =~ /box\.net\/shared/) {
    elsif ($abs =~ /http:\/\/www\.box\.net\/shared\S+/) {
	  	push @sample_urls, $abs;
    }
    elsif ($abs =~ /zippyshare\.com\/\S+.html/) {
	  	push @sample_urls, $abs;
    }
    elsif ($abs =~ /sendspace\.com\/file\/\S+/) {
	  	push @sample_urls, $abs;
    }
    #e.g. http://www.youtube.com/v/BteX5uIURIk&amp;hl=en_US&amp;fs=1&amp;
    elsif ($abs =~ /^http:\/\/www\.youtube\.com\/v\/(\w+)/) {
	  	push @sample_urls, "http://www.youtube.com/watch?v=" . $1;
      #http://www.easyyoutube.com/download/FfBVYhyXU8o/
	  	#push @sample_urls, "http://www.easyyoutube.com/download/" . $1 . "/";
    }
    elsif ($abs =~ /^http:\/\/(\S+)\.mp3$/) {
	  	push @sample_urls, $abs;
    }
  	
  }
  return make_unique(@sample_urls);
}#get_links_from_url


#
# Returns 0 if file successfully saved 
#
sub save_file {
  my $ret = 0;
  #eval {
  my ($url,$resp,$dir,$filename) = @_;
  if (!$url) {
    return "ERROR 2003: No URL";
  }
  print ("JRW>>>RESP=" . $resp);
  if (!$resp || !$resp->can('content_type')) {
    return "ERROR 2004: No RESPONSE";
  }
  my $MINLEN = 700000;
  my $ct = $resp->content_type();
 
  #First find the filename
  #Choices are in this order
  # 1. Filename from the content-disposition header.
  # 2. Filename from the url itself.
  if (!$filename && ($resp->filename && ($resp->filename . "" ne "null")) && ($resp->filename . "" ne "")) {
    $filename = $resp->filename;
  }
  #filename==?UTF-8?B?Sm9obm55IE1ha2VyIC0gU3VucmlzZSAtIEx1a2EgRCBFbGVjdHJvIEhvdXNlIE1peC5tcDM=?=
  if ($filename && ($filename =~ /^=\?UTF-8\?B\?(\S+)\?=$/)) {
    $filename = decode_base64($1);
    #$filename =~ s/\s+/_/g;
  } 
  $filename = "unknonwn_" . time . ".mp3" unless ($filename);
  if ($ct eq "application/octet-stream" || $ct eq "audio/mpeg" || $ct eq "application/x-download") {
    #we are ok.
  }
  #If content type is not mp3 or binary and the filename is not mp3, flag it.
  elsif (!($filename =~ /\.mp[3|4]$/i)) {
    $ret = "ERROR 2000: Unexpected file format '$ct' for file '$filename' on url $url";
    return $ret;
  }
  $filename = ($filename && $filename =~ /\.mp/) ? $filename : url2filename($url);

  return "ERROR: No filename" unless ($filename);
  #Remove any nasty characters
  $filename =~ s/>/_/g;
  $filename =~ s/</_/g;
  $filename =~ s/:/_/g;
  #Add the directory
	$filename = "$dir/" . $filename;
  debug(">>>>FILENAME: $filename");

  if (length($resp->content) < $MINLEN) {
    $ret = "ERROR 2001: Content length less than $MINLEN for url $url";
    string2file($resp->content,$filename . ".txt");
    return $ret;
  }
  if (!$resp->is_success) {
    $ret = "ERROR 2002: Unexpected code " . $resp->code() . " for url $url";         
    return $ret;
  }
  #Now save it.
  return string2file($resp->content,$filename);
}
sub string2file {
  my ($s,$filename) = @_;
	open (WAV,">$filename") || die "could not open '$filename'";
	binmode WAV;
	print WAV  $s;
	close WAV;
  return "could not create file" unless (-e $filename);
  return 0;
}

#
# Takes a downloadable url as input and generates a name that the file can
# be stored on disk.
#
sub url2filename {
	my $str = shift;
  my $split_char = '/';
	my @parts = split($split_char,$str);
	$str = $parts[$#parts];
  $str = (length($str) > 0) ? $str : $parts[$#parts - 1];
	#url decode
  $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	#just incase
	$str =~ s/\//_/g;                                      
	$str =~ s/ /_/g;                                      
	return $str;
} #get_wav_file_name


#
# Takes a filename as input and returs an array of lines
# All blanks, whitespace lines, and comments (#) are ignored.
#
sub filename2array {
  my $filename = shift;
  open (F,$filename) || die "Could not open file '$filename'";
  my @lines = (<F>);
  close F;
  my @real_lines = ();
  foreach (@lines) {
    if (/^\s+$/ || /^#/) {
      #Ignore, blanks, whitespace, and comments
    }
    else {
      chomp;
      push @real_lines,$_;
    }
  }#end foreach line
  return @real_lines;
}
sub array2filename {
  my $filename = shift;
  my @a = @_;
  open (F,">$filename") || die "Could not open file for write: '$filename'";
  print F join("\n",@a);
  close F;
}

sub append_array2filename {
  my $filename = shift;
  my @a = @_;
  open (F,">>$filename") || die "Could not open file for append: '$filename'";
  print F join("\n",@a);
  close F;
}

sub append2filename {
  my $filename = shift;
  my $item = shift;
  return unless $filename;
  chomp($item);
  open (F,">>$filename") || die "Could not open file for append: '$filename'";
  print F $item . "\n";
  close F;
}

#
# Pring MSG
#
sub debug {
  my $msg = shift;
  print ">>>$msg\n";
}


sub all_links_on_blogspot_blog {
  my $blogname = shift;
  #
  # Exploit the format of searching a date range on the blog:
  # e.g. 
  # http://trashbagskids.blogspot.com/search?updated-min=2001-01-01T00%3A00%3A00%2B11%3A00&updated-max=2010-01-01T00%3A00%3A00%2B11%3A00&max-results=44444
  my $url = "http://" . $blogname . ".blogspot.com/search?updated-min=2000-01-01T00%3A00%3A00%2B11%3A00&updated-max=" . today_as_blogspot_string() . "T00%3A00%3A00%2B11%3A00&max-results=44444";
  return get_links_from_url($url); 
}

sub usage {
   print <<USAGE;

 The first step is to harvest all the links to media files from the blog
 perl $0 -a getlinks -b <blog_name> -o <output_file> 
 perl $0 -a getlinks -u <url> -o <output_file>
 perl $0 -a getlinks -l <url_list_file> -o <output_file>
 where
   -a (action) getlinks instructs the script to harvest the links
   -b (blog_name) name of blog (e.g. use discodust for discodust.blogspot.com)
   -u (url) Instead of a blogspot blog, you can load any url and scrape it
   -l (url_list_file) instead of a blog or a url, you can load a text file of
      urls and scrape all of them.
   -o (output_file) a file to place the list of media links (e.g. links.txt)
   Examples:
   perl $0 -a getlinks -b discodust -o links.txt
   perl $0 -a getlinks -u http://teenagekicsusa.com -o links.txt
   perl $0 -a getlinks -l url_list.txt -o links.txt
 
 perl $0 -a download -i input_file -d directory_for_files -x ingnore_file
   -a (action) download instructs the script to download mp3s    
   -u (url) URL to scrape for mp3 links and download these                
   -l (url_list_file) instead of a blog or a url, you can load a text file of
      urls and scrape all of them.
   -i (input_file) a file of links to download.  This is the same filename as 
      output_file after you run the first command.
   -d is the directory of where the downloaded files should be placed.
   -x (ignore_file) a file of links that should be ignored.  If this file
      does not exist it is created. All links in the output_file are appended
      to this file.  It is used so you dont waste time downloading a link more
      than once.  A good convention is to name it 'harvested.txt' and use the
      same one for every blog.  That way if a link is duplicated in another
      blog you dont download it twice.

   Examples:
   * 1.
   * Download all the links in links.txt that are NOT in harvested.txt
   * and put them in the current directory
   perl $0 -a download -i links.txt -d . -x harvested.txt

   * 2.
   * Scrape the url http://dandeacon.com/mp3/ for links.  Ignore any that
   * appear in harvested.txt, download them all and put them in the current
   * directory
   perl $0 -a download -u http://dandeacon.com/mp3/ -d . -x harvested.txt

   * 3.
   * Scrape all the blog urls in blogs.txt and extract all of the urls on
   * each of them that are not found in harvested.txt.  Download all the 
   * files to the current directory. 
   perl $0 -a download -l blogs.txt -d . -x harvested.txt

   * 4.
   * Test the scripts ability to download zshare links by downloading the
   * file at http://www.zshare.net/download/65743488946614db/ and placing
   * it in the current directory.
   perl $0 -a test -u http://www.zshare.net/download/65743488946614db/ -d .

   * 5. 
   * Download all the links from http://molasuperpoco.com and print to STDOUT
   perl $0 -a getlinks -u http://molasuperpoco.com
USAGE
	 exit 1;
}#usage

sub today_as_blogspot_string {
  my ($day,$month,$year) = localtime[3,4,5];
  return sprintf("%04d-%02d-%02d",$year + 1900, $month + 1, $day);
}


##########################################################################
############################ ZIPPYSHARE ##################################
##########################################################################
sub get_zippyshare_resp {
  my $url = shift;
  my $resp = $b->get($url);
  my $content = $resp->content();
  my $mp3_url = "";
# This is the code we have to fake out:
#
#                            var pong = 'http%3A%2F%2Fwww4.serwus.com%2Fd%2F605854141s%2F1269289505%2F60585414.mp3';
#                            var  foken = unescape(pong.replace(/nnn/, "aaa").replace(/unl/g, "v"));
#                            foken = unescape(pong.replace(/serwus/, "zippyshare"));
#
  if ($content =~ /'(http%3A%2F%2F\S+\.mp3)'/) {
    my $part = $1;
    $part =~ s/%2F/\//g;
    $part =~ s/%3A/:/g;
    $part =~ s/serwus/zippyshare/g;
    $mp3_url = $part;
 }
  else {
    print ">>>BAD ZIPPYSHARE URL: $url";
    #FIXME - Better error return value ?
    return;
  }
  print ">>>ZIPPY:$mp3_url";
  $resp = $b->get($mp3_url,'Referer' => $url);
  print ">>>ZIPPY RESP:$resp";
  return $resp;
}#end get_zippyshare_resp


##########################################################################
############################ MEDIAFIRE  ##################################
##########################################################################
sub get_mediafire_resp {
  my $url = shift;
  my $code = $url;
  return unless ($url);
  if ($url =~ /^http:\/\/www\.mediafire.com\/\?(\S+)$/) {
    $code = $1;
  }
  elsif ($url =~ /^http:\/\/www\.mediafire.com\/download\.php\?(\S+)$/) {
    $code = $1;
  }
  elsif ($url =~ /^http:\/\/www\.mediafire.com\/file\/(\w+)\//) {
    $code = $1;
  }
  my $link_enc = get_downloadable_mediafire_url_for_code($code);
  debug("Could not get mediafire url for code $code") unless ($link_enc);
  return unless ($link_enc);
  return get_resp($link_enc,$cookies);
}#get_mediafire_resp 
 

sub get_downloadable_mediafire_url_for_code {
  my $code = shift;
  my $first_url = "http://www.mediafire.com/?" . $code;
  my $second_url = "";                                    
  my $resp = $b->get($first_url);
  my $content = $resp->content();
  #href="http://download59.mediafire.com/4cdfa246003g/ljwzz0mikyi/The+Living+%28Mighty+Mouse+Remix%29.mp3"> Click here to start download
  if ($content =~ /href="(http:\/\/[^"]+)"> Click here to start download/)
  {
     return $1;
  }
  else {
    debug("FAILED MATCH 1 on " . $content);
    return;      
  }
}#get_downloadable_mediafire_url_for_code
#GET /dynamic/download.php?qk=ljwzz0mikyi&pk=32226cd833f1592705996eb03f624a5b6af6f33099e5caea177c265926fb07c623580e2acaea68d77424dc0fd57493c8&r=aw3zd HTTP/1.1
#

##########################################################################
############################ BOX.NET ########3############################
##########################################################################
sub get_box_resp {
  #e.g. http://www.box.net/shared/ti1529i06a

  my $url = shift;
  return unless ($url);
  
  # Create a request
  my $req = HTTP::Request->new(GET => $url);

  # Pass request to the user agent and get a response back
  my $res = $b->request($req);

  my $content ="";
  # Check the outcome of the response
  if ($res->is_success) {
    $content = $res->content;
  }
  #
  # The line we are looking for looks like this:
  # e.g. http://www.box.net/index.php?rm=box_download_shared_file&file_id=f_655240213&shared_name=8d1ztf6140
  #
  # 
  if ($content =~ /href="(http:\/\/www\.box\.net\/index\.php\?rm=box_download_shared_file\S+shared_name=\S+)"/m) {
    my $actual_url = $1;
    $actual_url =~ s/&amp;/&/g;
    print ">>>ACTUAL URL=" . $actual_url . "\n";
    return get_resp($actual_url);
  }
  else {
    debug("Could not find downloadable link at box.net");
  }
  return 0;
}#get_zshare_resp
##########################################################################
############################ ZSHARE #########3############################
##########################################################################
sub get_zshare_resp {
  my $url = shift;
  return unless ($url);
  
  #Switch any audio zshare links to download.
  $url =~ s/\/audio\//\/download\//;
  
  #Get the content 

  # Create a request (zshare expects a post to the url with download=1 data
  my $req = HTTP::Request->new(POST => $url);
  $req->content_type('application/x-www-form-urlencoded');
  $req->content('download=1');

  # Pass request to the user agent and get a response back
  my $res = $b->request($req);

  my $content ="";
  # Check the outcome of the response
  if ($res->is_success) {
    $content = $res->content;
  }
  #
  # The line we are looking for looks like this:
  # var link_enc=new Array('h','t','t','p',':','/','/','6','9','.','8','0','.','2',' 5','4','.','1','7','9','/','d','o','w','n','l','o','a','d','/','4','2','0','a',' 4','7','6','2','c','c','f','7','e','f','2','f','7','c','1','0','9','2','e','3',' f','1','d','8','f','7','e','7','/','1','2','1','3','0','3','5','8','6','4','/',' 1','3','2','2','4','2','8','3','/','c','e','p','i','-','%','2','0','c','o','c',' o','t','t','e','%','2','0','i','n','%','2','0','m','y','%','2','0','h','e','a',' d','.','m','p','3');link = '';for(i=0;i<link_enc.length;i++){link+=link_enc[i];}
  # 
  if ($content =~ /var link_enc=new Array\((\S+)\)/m) {
    my $downloadable_url = "";             
    my $link_enc = $1;
    $link_enc =~ s/,//g;
    $link_enc =~ s/'//g;
    sleep(60); #wait 20 seconds for link to be active on server.
    debug("zshare link: " . $link_enc);
    return get_resp($link_enc,$cookies);
  }
  else {
    debug("Could not find downloadable link");
  }
}#get_zshare_resp
##########################################################################
############################ SENDSPACE ##################################
##########################################################################
sub get_sendspace_resp {
  my $url = shift;
  my $download_url;
  my $resp = $b->post($url,['download' => '&nbsp;REGULAR DOWNLOAD&nbsp;']);
  my $content = $resp->content();
  #<a id="downlink" class="mango" href="http://fs11n3.sendspace.com/dl/1ca61c2536f218a55628b49ea29a54ae/4abbaa5e0373dce5/70vebf/Slyde%20DJ%20mix.zip"   
  if ($content =~ /<a id="downlink" class="mango" href="(\S+)"/) {
    # e.g. $second_url looks something like this
    #http://fs11n3.sendspace.com/dl/1ca61c2536f218a55628b49ea29a54ae/4abbaa5e0373dce5/70vebf/Slyde%20DJ%20mix.zip
    $download_url = $1;
  }
  else {
    debug("FAILED MATCH CONTENT:\n$content");

    return;
  }
  return get_resp($download_url,$cookies);
}#end sub
##########################################################################
############################ YOUTUBE #####################################
##########################################################################
sub get_youtube_resp {
# First load the easyyoutube page for the vid:
# http://www.easyyoutube.com/download/dMH0bHeiRNg/
#
# Then load the easyyoutube download link:
# http://www.easyyoutube.com/download.php?id=dMH0bHeiRNg&action=download&type=18&btget=Download
#
# Then foloow the redirect.
# http://v1.lscache4.c.youtube.com/videoplayback?ip=0.0.0.0&sparams=id%2Cexpire%2Cip%2Cipbits%2Citag%2Calgorithm%2Cburst%2Cfactor&fexp=901803&algorithm=throttle-factor&itag=18&ipbits=0&burst=40&sver=3&expire=1262905200&key=yt1&signature=5B01FDB5244F57C2471403781DC4A8E2E2E9F7C9.2F03FD6C0D725FCC86F9E3DF380DF42977BCBFFC&factor=1.25&id=74c1f46c77a244d8
# 

  my $url = shift;
  my $easyyoutube_url;
  my $easyyoutube_download_url;
  my $easyyoutube_redirect_url;
  if ($url =~ /v=(\w+)$/) {
    $easyyoutube_url = "http://www.easyyoutube.com/download/" . $1 . "/";
    $easyyoutube_download_url = "http://www.easyyoutube.com/download.php?id=" . $1 . "&action=download&type=18&btget=Download";
  } 
  my $resp = $b->get($easyyoutube_url); #get cookies if we need em
  $resp = $b->get($easyyoutube_download_url,'Referer' => $easyyoutube_url); #get cookies if we need em
  my $ct = $resp->content_type();
  #MAKE SURE IT IS "video/mp4";
  #debug("code: " . $resp->status_line() . " " . $resp->content_type( ));
  return $resp;
}#end sub
