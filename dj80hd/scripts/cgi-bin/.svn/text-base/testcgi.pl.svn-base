#!/usr/bin/perl 
use CGI;
$q = new CGI;
$CONTENT_TYPE = "Content-type: text/html\n\n";
print $CONTENT_TYPE;
print "There are " . $#ARGV . " arguments, the first is " . $ARGV[0];
@names = $q->param;
foreach (@names) {
  print $_ . " : " . $q->param($_) . "<br>\n";
}
print "<hr>" . $ENV{'REMOTE_ADDR'} ;
