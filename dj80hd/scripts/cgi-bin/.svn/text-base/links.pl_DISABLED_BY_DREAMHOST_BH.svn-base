#!/usr/bin/perl -w

use CGI;
#FIXME - Need to defend gainst bad data.
#FIXME - Dont allow duplicates

$HTML_SPACE = " "; # "&nbsp;"
$HTML_NEWLINE = "<br>";
$q = CGI::new();
$DATA_FILE = "sslinks.txt";
print $q->header();
$name = $q->param("name");
$url = $q->param("url");
$MAX = 30;#Max links to keep

if ($q->param("submit"))
{
   &dosubmit;
}
&printmainpage;

sub dosubmit
{
   if (dataok($name,$url))
   {
     open(F, ">>$DATA_FILE") || die ("Could not open rw file: $DATA_FILE");
     #FIXME - Eliminate trialing whitespace.
     print F $name . "|" . $url . "\n";
     close F;
   }
   else
   {
     print "Invalid data entered.";
     exit;
   }
}
sub dataok
{
  my $name = shift;
  my $url = shift;
  #FIXME - do more error checking
  
  return (($name ne "") && ($url ne "") && (!($url =~ /blogspot\.com/)) && (!($url =~ /blogger\.com/)));
}
sub printmainpage
{
print "<html><body><title>SSLinkS</title><h1 align=\"center\">SSlinks</h1>\n";


&printlinks;

print "<hr><form method=\"post\"><a name=\"form\"><b>Enter a new one:</b></a><br/>Name (e.g. myurl)<input name=\"name\" value=\"novarra homepage\"/><br/>Absolute Url (e.g. http://lp.org): <input name=\"url\" value=\"http:\/\/www.novarra.com\" /><br/><input type=\"submit\" name=\"submit\" value=\"Add\" /></form><br/>";

print "<hr><b>Instructions:</b><br/>\n";
print "* The url for this page is <a href=\"http://scissorsoft.com/cgi-bin/links.pl\">http://scissorsoft.com/cgi-bin/links.pl</a> You can save some typing by using <a href=\"http://tinyurl.com/2m4ha5\">http://tinyurl.com/2m4ha5</a> but it will cost you one redirect.<br/>\n";
print "* Bookmark this url in your wireless browser.  (Both Novarra and Third Party are supported.)<br/>\n";
print "* Access the url with a normal browser (Firefox or IE) to add your links.<br/>\n";
print "* Reload the page in your wireless browser and your link should be there<br/>\n";
print "* The last $MAX entires will be displayed on this page.  This page can be accessed by the url <a href=\"http://tinyurl.com/2m4ha5\">http://tinyurl.com/2m4ha5</a> or directly via scissorsoft.  If you have any comments, quesions, corrections, complaints or bug reports, please email <a href=\"mailto:jim\@scissorsoft.com\">jim\@scissorsoft.com</a>";
print "</body></html>";
}

sub printlinks
{
   my $name = "";
   my $url = "";
   my $line = "";
   my @lines = ();

   open(F, "$DATA_FILE") || die ("Could not open rw file: $DATA_FILE");
   @lines = (<F>);
   close F;
   @lines = reverse @lines;
   #print "<blink>",$#lines ,$lines[0] ,"</blink>";
   if ($#lines > $MAX)
   {
     @lines = @lines[0..$MAX]
   }
   foreach $line (@lines)
   {
	   chop $line;
     ($name,$url) = split(/\|/,$line);
     if (&dataok($name,$url))
     {
     print "<a href=\"" . $url . "\">" . $name . "</a><br/>\n";
     }
     else
     {
       print "BAD DATA<br/>";
     }
   }

}

sub println
{
  print shift . "\n";
}

