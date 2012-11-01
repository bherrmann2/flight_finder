#!/usr/bin/perl -w
use CGI;
$q = new CGI;

#------------------- Configurable parameters ---------------------
$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f papl\@scissorsoft.com';
$VERSION = "0.1";
$LOGFILE = "papl.txt";
$CLIENT_DEAD_TAG = "-CLIENT FOUND DEAD-";
$URL = "http://scissorsoft.com/cgi-bin/papl.pl"; 
#$URL = "http://www.scissorsoft.com/cgi-bin/papl.pl"; 
$SCRIPT_ADMIN_EMAIL = "papl\@scissorsoft.com";

print $CONTENT_TYPE;

$raw_apl_data = $q->param("raw_apl_data");
$id = $q->param('id');

#
# 3 functions are allowed in Phase 0.5 Script
# 1. report apl. (expenced http params are raw_apl_data, interval_minutes, sessionid, and error(OPTIONAL)
# 2. test the apl script by entering your own data
# 3. view the log file
#

#Request to view only one entry
if ($id)
{
	doId();
	exit;
}

#Otherwise generate an id for what we are doing
$id = getId();

#Request to show the log file
if ($q->param("show"))
{
	doShow();
	exit;
}
#Check for dead clients
if ($q->param("ping"))
{
	doPing();
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
print "NO DATA WAS SUBMITTED ! <br><a href='?test=true'>Test PAPL</a><br><a href='?show=true'>Show existing data</a><br><a href='?ping=true'>Ping</a><br><form><input name=id><input type=submit value='Find this alert id'></form><br>\n";
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
	$to = getEmail($raw_apl_data);
}
if ($q->param("from"))
{
	$from = $q->param("from");
}
else
{
	$from = "papl\@scissorsoft.com";
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

#Write to log file
logIt();


# If there is an error, send an email alert
if (length($errorMsg)>1)
{
  print "<b>THIS APL DATA HAS AN ERROR !</b><br>";
  if( open(MAIL,"|$SENDMAIL -t"))
  {
   #$body = getMail($errorMsg . "\nraw_apl_data:\n" . $raw_apl_data);
   $body = getMail(cropString($errorMsg,50),$URL . "?id=$id");
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




#----------------------------------------------------------END MAIN
sub sendEmail #($to,$subject,$msg)
{
  my $to = shift;
  my $subject = shift;
  my $msg = shift;

  my $mail = "";
  $mail .= "To: ". $to . "\n";
  $mail .= "From: ". $SCRIPT_ADMIN_EMAIL . "\n";
  $mail .= "Cc: jwerwath\@novarra.com\n";
  $mail .= "Subject:" . $subject . "\n";
  $mail .= "\n\n";
  $mail .=  $msg . "\n\n";
  if( open(MAIL,"|$SENDMAIL -t"))
  {
   print MAIL $mail;
   close(MAIL);
	 print "This was piped to $SENDMAIL -t:<br><pre>", $mail,"</pre>";       
  }
  else
  {
    #Trouble with mail
		print "COULD NOT SEND EMAIL !";
  }
}#sendEmail

sub cropString
{
  my $s = shift;
  my $max = shift;
  if (length($s) > ($max - 4))
  {
    return substr($s,0,($max - 3)) . "...";
  }
  else
  {
    return $s;
  }
}


#Write the results of this request in the log file
sub logIt
{
	 my $log = getLog();
writeLineToLogFile($log);
}
sub nonewlines
{
	my $line = shift;
	$line =~ s/\n+//g;
	return $line;
}
sub writeLineToLogFile
{
	my $line = nonewlines(shift);
	
open(F,">>$LOGFILE") || die "Could not open $LOGFILE";
print F $line;
print F "\n";
close F;
}

#Get the one line of data to put in the log file.
# ...example... (note the first char (#) is not in the actual line it is just
# part of the perl comment
#
#
#*11725967198327:11:18:39, Tue Feb 27, 2007[NAME:j2me/5.2.24.1motv3xp/APL_threehk_aca_apl email=jim@scissorsoft.com con=60000 - 05.02.24.01 /motorola/motv3x .. h41.novarra.net DEVID=1169687493800 CHUNK=1468] [http://t50.novarra.net/performance/cnn/cnn/www.cnn.com/index.htm CON=8537 NET=5026 HTP=5071 IMT=144 IMN=4804 IMP=560 PNT=2042 TOT=27932 BYT=0 MEM=1117 CHK=1/1 STS=Thu, 25 Jan 2007 01:12:06 GMT CHT=534 AHT=4476 CIT=4229 AIT=997] ip=127.0.0.1 sessionid=80 point_of_contact=h52.novarra.net interval_minutes=5 CLIENT ERROR MESSAGE: DELETE THIS IF NO ERROR

sub getLog
{
 my $log = "";
 if (length($errorMsg)>0)
 {
	 $log .= "*";
 }
 else 
 {
	 $log .= "_";
 }
 $log .= $id . ":";
 $log .= getDateTime();
 $log .= $raw_apl_data . " ip=" . $ENV{'REMOTE_ADDR'} . " sessionid=" . $q->param('sessionid') . " point_of_contact=" . $q->param('point_of_contact') . " " . " interval_minutes=" . $q->param('interval_minutes') . " " . $errorMsg;
 $log =~ s/\s+/ /g;
 return $log;
}

#
# Get a "unique" 11 digit id
#
sub getId
{
 $x = time;
 #return substr($x, (length($x) - 9), 9) . substr(rand(),2,4) ;
 return $x . substr(rand(),2,4);
}
#Get text that is suitable for piping to sendmail 
#@params $msg - message to send in the email
sub getMail
{
  my $subject = shift;
	my $msg = shift;

$mail = "";
$mail .= "To: ". $to . "\n";
$mail .= "From: ". $from . "\n";
$mail .= "Cc: jwerwath\@novarra.com\n";
$mail .= "Subject:" . $subject . "\n";
$mail .= "\n\n";
$mail .=  $msg . "\n\n";
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
  print join "", getLines();
  print "</pre>";
}#doShow

sub doPing 
{
  my @lines =    getLines();

  #print "<b>GOT " . $#lines . " LINES !!</b>";
  #Get the last entry from each client
  my $lastEntries = {};
  foreach (@lines)
  {
	  my $line = $_;
	if (/^[_|\*|X](\d+).*\[NAME:([^\]]+)\](.*)/)
	{
		my $id = $1;
		my $name = $2;
		my $rest = $3;
		#print "$1 - <font color=green>$2</font> - <font color=red>$3</font> <br>";
		if (!grep(/^$name$/,keys(%$lastEntries)))
		{
			$lastEntries->{$name} = $line;
			#print "" . $name . " not in keys</blink><br>";
		}
		else
		{
			#print "" . $name . " IN keys</blink><br>";
		}
	}
	else
	{
		print "<b>ERROR:</b> no match ont this line: $line";
	}
  }
  @names = keys(%$lastEntries);
  print "<b>" . $#names .                     " ENTRIES FOUND </b><hr>";
  my $timenow = time;
  foreach (sort keys(%$lastEntries))
  {
	  my $data = $lastEntries->{$_};
	  $data =~ /interval_minutes=(\d+)/;
	  my $interval = $1;
	  $data =~ /^[\*|_](\d+)/;
	  my $id = $1;
	  $data =~ (/\[NAME:([^\]]+)\]/);
	  my $name = $1;
	  my $time = substr($id,0,length($id)-4);
	  #print $_ . "<font color=red>" . $lastEntries->{$_} . " </font> interval=<font color=blue>$interval</font> time is $time for id $id timenow is $timenow<br>";

	  if (($timenow - $time) > ($interval * 3 * 60 ))
	  {
		  if ($data =~ /$CLIENT_DEAD_TAG/)
		  {
			  #Client is already tagged as dead
		  print "<b>$name</b><br><font color=blue>CLIENT ALREADY DEAD</font><hr>\n";
		  }
		  else
		  {
		  print "<b>$name</b><br><font color=red>CLIENT UNEXPECTEDLY FOUND DEAD</font><hr>\n";
			  logDeadClient($data);

		  }
	  }
	  else
	  {
		  print "<b>$name</b><br><font color=green>CLIENT ALIVE</font><hr>\n";

	  }
	  
  }

  
}#doPing

sub getEmail
{
	my $email = "jwerwath\@novarra.com";
	my $source = shift;
	$source =~ /email=(\S+)/;
	if (length($1) > 3)
	{
		$email = $1;
	}
	$email =~ s/\]//g; #remove brackets from PAPL format
	return $email;
}
sub logDeadClient
{
	#find email to use
	my $line = shift;
	my $to = getEmail($line);                                         

	#send the message
	sendEmail($to,"PAPL ALERT: CLIENT FOUND DEAD!",$line);

	#log to file
	
	my $logline = "X" . substr($line,1) . " " . $CLIENT_DEAD_TAG;
	writeLineToLogFile($logline);                                        
}
sub getLines
{
  open(F,"$LOGFILE") || die "no $LOGFILE";
	my @lines = (<F>);
	close F;
	return reverse(@lines);
}
sub doId
{
  my $id = $id;
	my $out = join "", grep(/^[X|_|\*]$id/,getLines());
	$out = "NONE!" unless (length($out)>0); 
  print "<pre>$out</pre>";
}#doShow

#Print a form for the user to test the script
sub doTest
{
	print <<END_OF_TEST
<form method='post'>
raw_apl_data:<textarea name="raw_apl_data" rows=10 cols=80>
[NAME:j2me/5.2.24.1motv3xp/APL_threehk_aca_apl email=jwerwath\@novarra.com con=60000 - 05.02.24.01 /motorola/motv3x .. h41.novarra.net DEVID=1169687493800 CHUNK=1468]
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
		return "PAPL ALERT: " . $q->param("error");
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
		$error = "INVALID DATA";
	}
	$error = "PAPL ALERT: " . $error unless (!$error);
	return $error;
}
