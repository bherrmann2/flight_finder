use Archive::Tar;
use LWP;

my $TEST = 0;

#This url is used just to test the update and will load a smaller version of 
#the blacklists.
$test_url = "http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download&file=smalltestlist";

#This is the url that will load the complete blacklist file.
$real_url = "http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download&file=bigblacklist";

my $url = ($TEST) ? $test_url : $real_url;

$input = "bigblacklist.tar.gz";
save_url_as_file($url,$input);

#user of the script can override the default input file by passing it in as
#the first arg
if ($ARGV[0]) {
  $input = $ARGV[0];
}
print "Reading input file $input\n";

#
#If the size of the file is small we assume that urlblacklist.com has limited
#our update.
$size = -s $input;
die "Update limited by host." unless ($size > 1000);

#Now that we have the zip file, extract the porn and adult domains and put
#them in a file called porndomains.txt
$porn = Archive::Tar->new($input)->get_content('blacklists/porn/domains');
$outfile = 'porndomains.txt';
open(F,">$outfile") || die "Could not open $outfile";
print F $porn;
close F;
$adult = Archive::Tar->new($input)->get_content('blacklists/adult/domains');
open(F,">>$outfile") || die "Could not open $outfile";
print F $adult;
close F;

print "$outfile created.\n";

#
# Download a url and save the content as the file name specified.
#
sub save_url_as_file
{
	my $wavurl = shift;
	my $filename = shift;
  #print "Starting $wavurl ($filename)\n";
	my $b = LWP::UserAgent->new();
	my $resp = $b->get($wavurl);
	open (WAV,">$filename") || die "could not open '$filename'";
	binmode WAV;
	print WAV  $resp->content();
	close WAV;
	#print "...Done! $wavurl ($filename)\n";
}
