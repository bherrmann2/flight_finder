#!/usr/bin/perl -w
#
# Provides an interface to the 3PAPL (3rd Party Periodic Automated Profile Load)
#
# What we want from groundwork:
# - Automated graph of success %
# - Alarm on success % below x for y seconds
#
#
# What must the nagios plugin return for data ?
# - Nagios plugin returns only data for graphing.
#
#
# HISTORY
# Date        Author      Version Comment
#-----------  ----------- ------- ------------------------------------------
# 21-JUL-2008 jwerwath    1.0     Add ability to pass through nagios data if the url that was
#                                 Requested had nagios data in the X-Nagios HTTP Resp. Header
#
use LWP::UserAgent;
use Getopt::Std;   
use HTTP::Date;         
use URI::URL;

if ($#ARGV < 1)
{
   print <<USAGE;
USAGE: perl $0 -u <url> -t <timeout in seconds>

Optional parameters
-h <| delimeted, = seperated list of extra http headers to send>
   e.g. -h "User-Agent=My Crappy Script|X-MSISDN=666"
-c <content type to verify>
   e.g. -c "text/html"
-s <content size in bytes to verify>
   e.g. -s 69666
-g <string to grep for in content>
   e.g -g "If I got the correct page this line will be in the body of the html"

USAGE
	 exit 1;
}

#
# Get all our command line input into nice vars
my %o = ();
getopts("u:t:h:c:s:g:",\%o);
my $url = $o{"u"};
my $timeout = $o{"t"};
my %headers = extract_headers($o{"h"});
my $expected_content_type = $o{"c"};
my $expected_content_length = $o{"s"};
my $grepstring = $o{"g"};

my $ua = LWP::UserAgent->new;
$ua->timeout($o{"t"});
my $t1 = time;#print "+ $url\n";
my $response = $ua->get( $url, %headers );
#my $response = $ua->get( $url);
my $content = $response->content;
my $content_length = $response->content_length();
my $content_type = $response->content_type();
my $code = $response->code();
my $nagios = $response->header("X-Nagios");
my $t2 = time;
my $t3 = $t2 - $t1;
#print $content, "\n";
if ($timeout && $t3 >= $timeout)
{
	&error("Time $t3 is greater than limit $timeout");
}

if ($code == 200)
{
	if ($expected_content_type && (!($expected_content_type eq $content_type)))
	{
		&error("Received content-type != expected ($content_type != $expected_content_type)");
	}
	if ($grepstring && (!($content =~ /$grepstring/)))
	{
		&error("String '$grepstring' is not contained in the following content:$content");
	}
	if ($expected_content_length && (!($expected_content_length == $content_length)))
	{
		&error("Received content-length != expected ($content_length != $expected_content_length)");
	}
	&success($t3,$nagios);
}
else
{
	&error("HTTP " . $code);
}

sub extract_headers
{
	return extract_name_value_pairs(shift,'\|','=');
}

sub extract_name_value_pairs #($string, $record_seperator, $name_value_seperator)
{
	my $string = shift;
	my $record_sep = shift;
	my $name_value_sep = shift;
	my %ret = ();
	if (!$string) 
	{
		return %ret;
	}

	@pairs = split($record_sep,$string);
	foreach $pair (@pairs)
	{
		($name,$value) = split($name_value_sep,$pair);
		#print "<<<$name>>> <<<$value>>>\n";
		$ret{$name} = $value;
	}
	return %ret;
}

#
# Send a success message back to nagios
#
sub success #($seconds,$nagios)
{
	my ($secs,$nagios) = @_;        
  my $msg = (length($nagios) > 0) ? $nagios : "OK|secs=$secs" . "s" ;
	print $msg;
	exit 0;
}

sub error #($msg)
{
	my $msg = "[$url]" . shift;
	print $msg;
	exit 2;
}
