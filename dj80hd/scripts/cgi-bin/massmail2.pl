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
	print "<table border>";
	print "<tr><td>FROM <i>(enter the email address of the sender)</i><td><input name=from value='werwath\@gmail.com'><br>";
	print "<tr><td>PASSWORD <i>(enter the password to use this tool)</i><td><input type=password name=pass><br>";
	print "<tr><td>EMAIL ADDRESS <i>(enter any text file containing email addresses.  The addresses will be automatically extracted and used.  Simply overwrite the sample data provided.)</i><td><textarea cols=80 rows=20 name=names>
werwath\@gmail.com
some other stuff in a file bla bla
werwath\@hotmail.com
	</textarea><br>";
	print "<tr><td>SUBJECT <i>(enter the subject for the mass mail)</i><td><input name=subject value='Subject for mass mail'><br>";
	print "<tr><td>MESSAGE <i>(enter the body of the mass mail you wish to send)</i><td><textarea cols=80 rows=10 name=msg>Type the message here.             </textarea><br>";
	print "<tr><td><td><input type=submit name=action value=Go><input type=reset><br>";
	print "</table></form>";
	exit 0;
}
if ($pass ne "1969")
{
	print "Password is incorrect.";
	exit 0;
}

@emails = extractEmails($names);
print "Mail sent to the following addresses:<br>";
foreach $email (@emails)
{
	$email =~ s/^\s+//;
	$email =~ s/\s+$//;
	print "<li>" . $email unless (!$email);
	&sendEmail($email,$from,"",$subject,$msg);
}
#sendEmail($email,$FROM_EMAIL,"","Survey:$origname",$msg);

sub extractEmails
{
	#$haystack =           shift;
	#@needles = split(/\s+/,$haystack);
	#print join('</b><br><b>',@needles);
	#@emails = grep(/[A-Z0-9._%-]+@[A-Z0-9._%-]+\.[A-Z]{2,4}/,@needles);
	$_ = shift;
	@emails = /([a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,4})/gi;
	return @emails;
}
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
