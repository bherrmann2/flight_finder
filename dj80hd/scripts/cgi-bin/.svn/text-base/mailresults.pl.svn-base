#!/usr/bin/perl -w
use CGI;
$q = new CGI;

$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f webform@wimkp.org';
$VERSION = 11;
print $CONTENT_TYPE;

if ($q->param("show"))
{
print "<pre>";
open(F,"mailresults.txt") || die "no mailresults.txt";
foreach (<F>)
{
print $_;
}
close F;
print "</pre>";
exit;
}
if ($q->param("to"))
{
	$to = $q->param("to");
}
else
{
	$to = "werwath\@gmail.com";
}
if ($q->param("from"))
{
	$from = $q->param("from");
}
else
{
	$from = "jim\@scissorsoft.com";
}
if ($q->param("subject"))
{
	$subject = $q->param("subject");
}
else
{
	$subject = "RESULTS";
}
if ($to)
{
 if( open(MAIL,"|$SENDMAIL -t"))
 {
   print MAIL getMail();
   close(MAIL);
	 print "This was piped to $SENDMAIL -t:<br>", getMail();
	 print "<hr><a href=\"mailtest.pl\">AGAIN</a><hr>";
 }
 else
 {
  print "ERROR: Mail not sent !";
 }
 open(F,">>mailresults.txt") || die "Could not open mailresults.txt";
 $log = getDateTime() . ": " . getMail();
 $log =~ s/\s+/_/g;
 print F $log;
 print F "\n";
 close F;
}
else
{
print "NO EMAIL SPECIFIED.<br>";
print getMessage();
}

print "Done.  (version $VERSION)";


sub getMail
{

$mail = "";
$mail .= "To: ". $to . "\n";
$mail .= "From: ". $from . "\n";
$mail .= "Cc: jwerwath\@novarra.com\n";
$mail .= "Subject:" . $subject . "\n";
$mail .= "\n\n";
$mail .=  getMessage() . "\n\nThank you " . $q->param("to") .".\n";
$mail .= "(version $VERSION) \n";
return $mail;
}

sub getDateTime
{
@months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
$year = 1900 + $yearOffset;
$theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
return $theTime;
}
sub getMessage
{
  my $ret = "";  

my @names = $q->param;
foreach (@names) {$ret .= "\n$_:\n" . $q->param($_);}
  return $ret;

}#getMsg

