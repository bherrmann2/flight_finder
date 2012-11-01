#!/usr/bin/perl -w
use CGI;
$q = new CGI();
print "Content-Type: text/html\n\n";

$content = $q->param("content");
$seperator = $q->param("seperator");
$unique = $q->param("unique");

%SEP_CHAR = ("SEMICOLON" => ";", "COMMA" => ",", "NEWLINE" => "\n");
$seperator = $SEP_CHAR{$seperator};

if ($content)
{
	$out = "";
	@parts = split /\s+|;|,/, $content;
	@emails = ();
	foreach $part (@parts)
	{
		if ($part =~ /([\w|\-|\.|_]+\@[\w|\-\_\.]+)/)
		{
		  push @emails,$1;
		}
		#if ($part =~ /(\S+\@\w+\.\w+\.\w+)/)
		#{
		#  push @emails,$1;
		#}
	}
	if ($unique)
	{
	   %seen = (); @unique = grep { ! $seen{$_} ++} @emails;
		 $out = join($seperator,sort @unique);
	}
	else
	{
	   $out = join($seperator,sort @emails);
	}
print "<pre>$out</pre>";

}
else
{
	print "<form method=post><textarea name=content rows=40 cols=80>Enter text from which to extract email addresses. Below is an example:

Bob Garmin
43 Fremont Avenue N.
Shoreline, WA  98133
(206) 742-1763
dereachan\@hotmail.com

Ed Faust
7720 NE 109th Court
Vancouver, WA  98662
(770) 896-7799
ftdama\@shardlabs.com

Curtis Blow
401 16th Street South
Both, WA  98012
(206) 847-3833
curtt444444\@hotmail.com

	
	
	</textarea><br>Select a seperator for your email list: <select name=seperator><option>SEMICOLON<option>NEWLINE<option>COMMA</select><br><input type=checkbox CHECKED name=unique value=yes>Remove duplicates<br><input type=submit value=Go></form>";
}


