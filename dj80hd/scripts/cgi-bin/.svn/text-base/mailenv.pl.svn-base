#!/usr/bin/perl -w
use CGI;
$q = new CGI;

$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f webform@wimkp.org';
$VERSION = 11;
print $CONTENT_TYPE;

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
	$subject = "ENV TEST";
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
$mail .=  getMessage() . "\n\nThank you " . $q->param("to") .".  Questions or Comments ?  Please email Jim Werwath (jim\@scissorsoft.com)\n";
$mail .= "(version $VERSION) \n";
return $mail;
}

sub getMessage
{
  my $ret = "";  
foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    $ret .= "${var}=\"${val}\"<br>\n";
}
my @names = $q->param;
foreach (@names) {$ret .= "<b>$_</b>=" . $q->param($_);}
  return $ret;

}#getMsg

