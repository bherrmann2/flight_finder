#! /usr/bin/perl -w
#! perl -w

use CGI;
#----------------------- TO BE CONFIGURED ------------------------------
$REAL_EMAIL = 1;
$DEBUG = 0;
$SENDMAIL = '/usr/lib/sendmail ';
#-----------------------------------------------------------------------
$q = new CGI;
print $q->header();
if ($REAL_EMAIL && ($ENV{'HTTP_HOST'} =~ m/127\.0\.0\.1/))
{
	$REAL_EMAIL = 0; #no real email for localhost
}
$action = $q->param('action');
$names = $q->param('names');
$subject = $q->param('subject');
$msg = $q->param('msg');
$from = $q->param('from');
$pass = $q->param('pass');
if (! $action)
{
	print "<form method=post>";
	print "from:<input name=from><br>";
	print "pass:<input type=password name=pass><br>";
	print "to:<textarea name=names>Enter names here</textarea><br>";
	print "subject:<input name=subject><br>";
	print "msg:<textarea name=msg>Enter msg</textarea><br>";
	print "<input type=submit name=action value=Go><input type=reset><br>";
	print "</form>";
	exit 0;
}
if ($pass ne "caa69?")
{
	print "Password is incorrect.";
	exit 0;
}

@emails = split(/\s+|,/,$names);
foreach $email (@emails)
{
	$email =~ s/^\s+//;
	$email =~ s/\s+$//;
	print "<li>" . $email unless (!$email);
	&sendEmail($email,$from,"",$subject,$msg);
}
#sendEmail($email,$FROM_EMAIL,"","Survey:$origname",$msg);
sub sendEmail
{
	($to,$from,$cc,$subject,$msg) = @_;
	$mail = "";
	$mail .= "To: ". $to . "\n";
	$mail .= "From: ". $from . "\n";
	$mail .= "Cc: jwerwath\@novarra.com\n";
	$mail .= "Subject:" . $subject . "\n";
	$mail .= "\n\n";
	$mail .= $msg. " \n";
	if (! $REAL_EMAIL)
	{
		print "<hr>This message sent to $to from $from cc $cc subject $subject:</br>" unless (!$DEBUG);
		$mail =~ s/\n/<br>/g;
		print $mail, "<hr>";
		
		return;
	}
	if( open(MAIL,"|$SENDMAIL -t"))
	{
		print MAIL $mail;
		close(MAIL);
 	}
	else
	{
 		print "ERROR: Mail not sent !";
	}
}#sendMail
