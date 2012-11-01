#!/usr/bin/perl -w

use CGI;


$HTML_SPACE = " "; # "&nbsp;"
$HTML_NEWLINE = "<br>";
$q = CGI::new();

print $q->header();
$data = $q->param("data");
$example = $q->param("example");

print "<h1 align=center>MAX POST TESTER</h1><form method=post><textarea cols=106 rows=32 name=data>";

  	if ($example eq "Example Data That Works")
	{
	for ($i=0;$i<10000;$i++) {print "0";}
	}
	elsif ($example eq "Example Data That Fails") 
	{
	for ($i=0;$i<30000;$i++) {print "X";}
	}

print "</textarea><br>";
print "<input type=submit name=example value='Example Data That Works'>";
print "<input type=submit name=example value='Example Data That Fails'>";
print "<input type=submit name=test value='Test It !'>";

print "<input type=reset></form>";

if ($q->param("test"))
{
	print "<HR>SUCCESS! Got " . len($data) . " characters !";

}
else 
{
	print "<HR>No data entered.";
}
