#!/usr/bin/perl -w

use CGI;
$q = CGI::new();
print $q->header();
print "<html><body>";
print "RESULTS:<br>";
@names = $q->param;
foreach (@names) {print "<b>$_</b>=" . $q->param($_);}
print "</body></html>";
