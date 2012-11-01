#!/usr/bin/perl -w
#!perl -w
use CGI;
$q = new CGI;

#------------------- Configurable parameters ---------------------
$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f jim\@scissorsoft.com';
$VERSION = 11;
$LOGFILE = "papl.txt";
$SCRIPT_ADMIN_EMAIL = "jim\@scissorsoft.com";

print $CONTENT_TYPE;

$raw_apl_data = $q->param("raw_apl_data");

#
# 3 functions are allowed in Phase 0.5 Script
# 1. report apl. (expenced http params are raw_apl_data, interval_minutes, sessionid, and error(OPTIONAL)
# 2. test the apl script by entering your own data
# 3. view the log file
#

#Request to show the log file
if ($q->param("show"))
{
	doShow();
	exit;
}
#Request to show the test interface
if ($q->param("test"))
{
	doTest();
	exit;
}

#From here on in we expect to have APL data
#so if is not there, tell user what they can do.
if (!$raw_apl_data)
{
print "NO DATA WAS SUBMITTED ! <br><a href='?test=true'>Test PAPL</a><br><a href='?show=true'>Show existing data</a>\n";
exit;
}

#Find the email address to send alerts.
#This can be specified as a "to" parameter, or it can be embedded in the APL
#name as email=<emailaddr> e.g. email=joe@blow.com
#default
if ($q->param("to"))
{
	$to = $q->param("to");
}
else
{
	if ($raw_apl_data =~ /email=(\S+)/)
	{
		$to = $1;
	}
	else
	{
		$to = $SCRIPT_ADMIN_EMAIL;
	}
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
	$subject = "PAPL ALERT";
}

#Determine the error message (if any)
$errorMsg = getErrorMessage();


# If there is an error, send an email alert
if (length($errorMsg)>1)
{
  print "<b>THIS APL DATA HAS AN ERROR !</b><br>";
  if( open(MAIL,"|$SENDMAIL -t"))
  {
   $body = getMail($errorMsg . "\nraw_apl_data:\n" . $raw_apl_data);
   print MAIL $body;
   close(MAIL);
	 print "This was piped to $SENDMAIL -t:<br>", $body;       
  }
  else
  {
    #Trouble with mail
		print "COULD NOT SEND EMAIL !";
  }
}
else
{
print "NO ERRORS TO REPORT FROM THIS REQUEST:<br>";
print getDump();
}


#Write to log file
logIt();


#----------------------------------------------------------END MAIN


#Write the results of this request in the log file
sub logIt
{
open(F,">>$LOGFILE") || die "Could not open $LOGFILE";
print F getLog();
print F "\n";
close F;
}

#Get the one line of data to put in the log file.
sub getLog
{
 $log = "";
 if (length($errorMsg)>0)
 {
	 $log .= "*";
 }
 else 
 {
	 $log .= "_";
 }
 $log .= getDateTime();
 $log .= $raw_apl_data . " ip=" . $ENV{'REMOTE_ADDR'} . " sessionid=" . $q->param('sessionid') . " point_of_contact=" . $q->param('point_of_contact') . " " . " interval_minutes=" . $q->param('interval_minutes') . " " . $errorMsg;
 $log =~ s/\s+/ /g;
 return $log;
}

#Get text that is suitable for piping to sendmail 
#@params $msg - message to send in the email
sub getMail
{
	$msg = shift;

$mail = "";
$mail .= "To: ". $to . "\n";
$mail .= "From: ". $from . "\n";
$mail .= "Cc: jwerwath\@novarra.com\n";
$mail .= "Subject:" . $subject . "\n";
$mail .= "\n\n";
$mail .=  $msg . "\n\n";
$mail .= "(papl.pl version $VERSION) \n";
return $mail;
}

#Get the current time in a human readable format
sub getDateTime
{
@months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
$year = 1900 + $yearOffset;
$theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
return $theTime;
}


#Get a dump of what was sent
sub getDump
{
  my $ret = "";  
  my @names = $q->param;
  foreach (@names) {$ret .= "\n$_:\n" . $q->param($_);}
  return $ret;
}#getMsg

#Print the output of the log file in html format
sub doShow
{
  print "<pre>";
  open(F,"$LOGFILE") || die "no $LOGFILE";
	@lines = (<F>);
  foreach (reverse(@lines))
  {
    print $_;
  }
  close F;
  print "</pre>";
}#doShow

#Print a form for the user to test the script
sub doTest
{
	print <<END_OF_TEST
<form method='post'>
raw_apl_data:<textarea name="raw_apl_data" rows=10 cols=80>
[NAME:j2me/5.2.24.1motv3xp/APL_threehk_aca_apl email=jim\@scissorsoft.com con=60000 - 05.02.24.01 /motorola/motv3x .. h41.novarra.net DEVID=1169687493800 CHUNK=1468]
[http://t50.novarra.net/performance/cnn/cnn/www.cnn.com/index.htm CON=8537 NET=5026 HTP=5071 IMT=144 IMN=4804 IMP=560 PNT=2042 TOT=27932 BYT=0 MEM=1117 CHK=1/1 STS=Thu, 25 Jan 2007 01:12:06 GMT CHT=534 AHT=4476 CIT=4229 AIT=997]
</textarea><br>
interval_minutes: <input type="text" name="interval_minutes" value="5" /><br>
sessionid: <input type="text" name="sessionid" value="80"/><br>
error: <input type="text" name="error" value="DELETE THIS IF NO ERROR" /><br>
point_of_contact: <input type="text" name="point_of_contact"/ value="h52.novarra.net"><br/>
<input type='submit' value='Test' />
</form>


END_OF_TEST
}

#Get the error message if one exists.
sub getErrorMessage
{
  #If client had an error, just use that
	if ($q->param("error"))
	{
		return "CLIENT ERROR MESSAGE: " . $q->param("error");
	}
	
	#Now we check the timestamp thresholds...
	
	$error = "";
	if ($raw_apl_data =~/\[NAME:(.+)\]\s+\[(.*)\]/)
	{
	  #split the apl data into the name and data parts
		$name = $1;
		$data = $2;
		foreach $timestamp ("con","net","tot")
		{
		  #check for limits that are specified as part of the name.
			if ($name =~ /$timestamp=(\d+)/i)
			{
				$limit = $1;	
				if ($data =~ /$timestamp=(\d+)/i)
				{
				  #if limit is exceeded, report it.
					if ($1 >  $limit)
					{
						$error .= "$timestamp time of $1 exceeds limit of $limit\n";
					}
				}
			}
		}
	}
	else
	{
		$error = "APL DATA HAS INVALID FORMAT";
	}
	return $error;
}
