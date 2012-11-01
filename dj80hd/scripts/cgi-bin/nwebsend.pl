#!/usr/bin/perl -w


use CGI;
$q = new CGI;

$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f webform@wimkp.org';
$VERSION = 10;
print $CONTENT_TYPE;
$to = $q->param("to");
$msg = $q->param("msg");
$url = $q->param("url");
if (! $q->param("to"))
{
   print "ERROR: No email address was specified in the Options";
  exit 0; 
}
elsif (! ($to =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/))
{
 		 print "ERROR: The following email address is not valid: $to";
  exit 0; 
}
if (! $q->param("msg"))
{
    print "ERROR: Empty message.";
  exit 0; 
}
#FIXME - check the format of the to address.
if ($to)
{
	$from = $q->param("from");
	$from = "mail\@novarra.com" unless ($from);
	$subject = $q->param("subject");
	$subject = "URL for U" unless ($subject);

  if( open(MAIL,"|$SENDMAIL -t"))
  {
   print MAIL getMail();
   close(MAIL);
   #print "This was piped to $SENDMAIL -t:<br>", getMail();
	#print "<hr><a href=\"mailtest.pl\">AGAIN</a><hr>";
   print "Email sent to $to <hr>$msg<br/>";
	 if ($url) 
	 {
	 	print "<a href='" . $url . "'>BACK</a>";
		}
		else
		{
		print "Use the back button on your browser to go back.";
		}
  }
  else
  {
    print "ERROR: Mail not sent !";
  }
}
else
{
	print "ERROR: No data in email.";
}

sub getMail
{
$mail = "";
$mail .= "To: ". $q->param("to") . "\n";
$mail .= "From: ". $from . "\n";
$mail .= "Cc: jwerwath\@novarra.com\n";
$mail .= "Subject:" . $subject . "\n";
$mail .= "\n\n";
$mail .= $msg . "\n";
return $mail;
}

