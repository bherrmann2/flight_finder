#!/usr/bin/perl
use Socket;
$|=1;
##################################################################  
#  birdcast.cgi Version 2.1
#  updated Nov 2, 2002
#  (C)1998-2002 Bignosebird.com                                          
#  This software is FREEWARE! Do with it as you wish. It is yours   
#  to share and enjoy. Modify it, improve it, and have fun with it! 
#  It is distributed strictly as a learning aid and bignosebird.com 
#  disclaims all warranties- including but not limited to:          
#  fitness for a particular purpose, merchantability, loss of       
#  business, harm to your system, etc... ALWAYS BACK UP YOUR        
#  SYSTEM BEFORE INSTALLING ANY SCRIPT OR PROGRAM FROM ANY          
#  SOURCE!
##################################################################  

# CONFIGURATION NOTES 

#
# $SCRIPT_NAME is the full URL of this script, including the 
# http part, ie, "http://domainname.com/cgi-bin/birdcast.cgi";
#
# $SITE_NAME is the "name" of your web site.
# $SITE_URL is the URL of your site (highest level)
# $END_LINE is the very last line printed in the e-mail.
#
# $MAXNUM is the number of possible people a person can refer
# your URL to at one time. If you call the script using the
# GET method, then this is also the number of entry blanks
# created for recipient names and addresses.
#
# $SMTP_SERVER is the name of your e-mail gateway server, or
# SMTP host. On most systems, "localhost" will work just fine.
# If not, change "localhost" to whatever your ISP's SMTP
# server name is, ie, smtp.isp.net or mail.isp.net

# $SEND_MAIL is the full path to your server's sendmail program
# If you do not wish to use Sockets for some reason and need
# to use sendmail, uncomment the $SEND_MAIL line and comment
# the $SMTP_SERVER line.

# okaydomains is a list of domains from which you want to allow
# the script to be called from.  Leave it commented to leave the
# script unrestricted. If you choose to use it, be sure to list
# your site URL with and without the www.

#  Use either $SMTP_SERVER 
#   $SMTP_SERVER="localhost";
#
#     OR
#
#   $SEND_MAIL="/usr/lib/sendmail -t"; 
$SEND_MAIL = '/usr/lib/sendmail -t';
#
#      BUT NEVER BOTH!!!!!!
#

   $error = "";

    @okaydomains=("http://www.scissorsoft.com", "http://scissorsoft.com");

   $SCRIPT_NAME="http://www.scissorsoft.com/cgi-bin/birdcast.cgi";
   $SITE_NAME="The Name of Your Site";
   $SITE_URL="http://scissorsoft.com/";
   $ENDLINE="";
   $MAXNUM=3;
   $LOGFILE="reflog.txt";

   if ($SENDMAIL ne "")
     {&test_sendmail;}


   &valid_page;    #if script is called from offsite, bounce it!
   &decode_vars;
   $error = &check_emails_for_errors;   
   if (( $ENV{'REQUEST_METHOD'} ne "POST") || $error)
    {
	    if ($error)
	    {
		    $error = "<br>Please correct the following errors:<br>" . $error;
	    }
      &draw_request;
      exit;
    }
   &do_log;
   &process_mail;
   print "Location: http://bionomicgardener.com/1995order.html\n\n"; #$JUMP_TO\n\n";

##################################################################
sub process_mail
 {
for ($i=1;$i<$MAXNUM+1;$i++)
    {
      $recipname="recipname_$i";
      $recipemail="recipemail_$i";
      if ($fields{$recipemail} eq "")
        {
         next;
        }
      if (&valid_address == 0)
        {
         next;
        }

#BNB SAYS! You can modify the Subject line below.

$subject = "Suggestion from $fields{'send_name'}";

#BNB SAYS! Modify the lines below between the lines marked
# with __STOP_OF_MAIL__ to customize your e-mail message
# DO NOT remove the lines that contain __STOP_OF_MAIL__!
# If you enter any hardcoded e-mail addresses, BE SURE TO
# put the backslash before the at sign, ie, me\@here.net

$msgtxt = <<__STOP_OF_MAIL__;            
Hi $fields{$recipname},

$fields{'send_name'} stopped by $SITE_NAME 
and suggested that you visit the following URL:

   $JUMP_TO

__STOP_OF_MAIL__

      if ($fields{'message'} ne "")
       {
         $msgtxt .= "Here is their message....\n";
         $msgtxt .= "$fields{'message'}\n\n";
       }
       $msgtxt .= "$SITE_NAME\n";
       $msgtxt .= "$ENDLINE\n";
       $msgtxt .= "$SITE_URL\n\n";
       $mailresult=&sendmail($fields{send_email}, $fields{send_email}, $fields{$recipemail}, $SMTP_SERVER, $subject, $msgtxt);

      if ($mailresult ne "1")
      {print "Content-type: text/html\n\n";
       print "MAIL NOT SENT. SMTP ERROR: $mailresult\n";
       exit
      }

    }
 }

##################################################################
sub draw_request
 {
print "Content-type: text/html\n\n";

#BNB SAYS! Here is the part that draws the page that asks the 
#reader to enter e-mail addresses and names. Tailor it to meet
# your needs if necessary. DO NOT disturb the lines with
# __REQUEST__ on them.

print <<__REQUEST__;
<BODY BGCOLOR="#FFFFFF">
<CENTER>
<P>                                                               
<TABLE WIDTH=550 BGCOLOR="CCE6FF">
 <TR>
 <TD>
 <FONT FACE="ARIAL" SIZE=4 COLOR="#009999">
  <B>
  <CENTER>
  SUGGEST THIS PAGE TO A FRIEND...<P>
  <A HREF="$ENV{'HTTP_REFERER'}">$ENV{'HTTP_REFERER'}</A>
  </CENTER>
  </B>
  </FONT>
  <BLOCKQUOTE>
 <FONT FACE="ARIAL" SIZE=2 COLOR="#000000">
  If you have a friend that you would like to recommend this page to,
  or if you just want to send yourself a reminder, here is the easy
  way to do it!
  <P>
  Simply fill in the e-mail address of the person(s) you wish to tell
  about $SITE_NAME, your name and e-mail address (so they do
  not think it is spam or reply to us with gracious thanks),
  and click the <B>SEND</B> button.
  If you want to, you can also enter a message that will be included
  on the e-mail.
  <P>
  After sending the e-mail, you will be transported back to http://bionomicgardener.com/1995order.html
 </FONT>
 <b><font color=red><br>$error</font></b>
<FORM METHOD="POST" ACTION="$SCRIPT_NAME">
   <INPUT TYPE="HIDDEN" NAME="call_by" VALUE="$ENV{'HTTP_REFERER'}">
   <TABLE BORDER=0 CELLPADDING=1 CELLSPACING=0 >
    <TR>
    <TD>&nbsp;</TD>
    <TD ALIGN=CENTER><B>Name</B></TD>
    <TD ALIGN=CENTER><B>E-Mail Address</B><TD>
    </TR>
    <TR>
    <TD><B>You</B></TD>
    <TD><INPUT TYPE="TEXT" NAME="send_name" value="$fields{'send_name'}"></TD>
    <TD><INPUT TYPE="TEXT" NAME="send_email" value="$fields{'send_email'}"></TD>
    </TR>
__REQUEST__
    print <<__ROWS__;
    <TR>
    <TD><B>Friend 1</B></TD>
    <TD><INPUT TYPE="TEXT" NAME="recipname_1" value="$fields{'recipname_1'}"></TD>
    <TD><INPUT TYPE="TEXT" NAME="recipemail_1" value="$fields{'recipemail_1'}"></TD>
    </TR>
    <TR>
    <TD><B>Friend 2</B></TD>
    <TD><INPUT TYPE="TEXT" NAME="recipname_2" value="$fields{'recipname_2'}"></TD>
    <TD><INPUT TYPE="TEXT" NAME="recipemail_2" value="$fields{'recipemail_2'}"></TD>
    </TR>
    <TR>
    <TD><B>Friend 3</B></TD>
    <TD><INPUT TYPE="TEXT" NAME="recipname_3" value="$fields{'recipname_3'}"></TD>
    <TD><INPUT TYPE="TEXT" NAME="recipemail_3" value="$fields{'recipemail_3'}"></TD>
    </TR>
__ROWS__
    print <<__REQUEST2__;            
   <TR>
   <TD>&nbsp;</TD>
   <TD ALIGN=CENTER COLSPAN=2>
   <B>Your Message</B><BR>
 <textarea name="message" wrap=virtual rows=5 cols=35></textarea>
    <BR>
    <INPUT TYPE="submit" VALUE="SEND">
    </TD>
    </TR>
  </TABLE>
    </FORM>
  </BLOCKQUOTE>
   <CENTER>
    <FONT SIZE="-1">
    Free recommendation script created by<BR>
    </FONT>
    <A HREF="http://bignosebird.com/"><B>BigNoseBird.Com</B></A><BR>
    <FONT SIZE="-1">
    <I>The Strangest Name in Free Web Authoring Resources<I><BR>
    </FONT>
    <P>
   </CENTER>
  </TD>
  </TR>
  </TABLE>
__REQUEST2__
 }

##################################################################
#  NOTHING TO MESS WITH BEYOND THIS POINT!!!!
##################################################################
sub decode_vars
 {
 $i=0;
  if ( $ENV{'REQUEST_METHOD'} eq "GET")
   {
     $temp=$ENV{'QUERY_STRING'};
   }
   else
    {
      read(STDIN,$temp,$ENV{'CONTENT_LENGTH'});
    }
  @pairs=split(/&/,$temp);
  foreach $item(@pairs)
   {
    ($key,$content)=split(/=/,$item,2);
    $content=~tr/+/ /;
    $content=~s/%(..)/pack("c",hex($1))/ge;
    $content=~s/\012//gs;
    $content=~s/\015/ /gs;
    $fields{$key}=$content;
   }
   if ($fields{'call_by'} eq "")
    {
     $JUMP_TO = $ENV{'HTTP_REFERER'};
    }
   else
    {
     $JUMP_TO = $fields{'call_by'};
    }
}

##################################################################
sub valid_address 
 {
  $testmail = $fields{$recipemail};
  if ($testmail =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||
  $testmail !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/)
   {
     return 0;
   }
   else 
    {
        return 1;
    }
}
#returns an error msg - empty if there is no error
sub check_emails_for_errors #()
{
	$err = "";
	if (!($fields{"send_name"}))
	{
		$err .= "Your name is empty.<br>";
	}
	if (!(valid_email($fields{"send_email"})))
	{
		$err .= "Your email is not valid.<br>";
	}
	if (!($fields{"recipemail_1"}))
	{
		$err .= "Email #1 is empty.<br>";
	}
	if ($fields{"recipemail_1"} && (!valid_email($fields{"recipemail_1"})))
	{
		$err .= "Email #1 is not valid.<br>";
	}
	if ($fields{"recipemail_2"} && (!valid_email($fields{"recipemail_2"})))
	{
		$err .= "Email #2 is not valid.<br>";
	}
	if (!($fields{"recipemail_2"}))
	{
		$err .= "Email #2 is empty.<br>";
	}
	if ($fields{"recipemail_3"} && (!valid_email($fields{"recipemail_3"})))
	{
		$err .= "Email #3 is not valid.<br>";
	}
	if (!($fields{"recipemail_3"}))
	{
		$err .= "Email #3 is empty.<br>";
	}
	return $err;
}
sub valid_email  #($email) 
 {
  $testmail = shift;                   
  if ($testmail =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||
  $testmail !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/)
   {
     return 0;
   }
   else 
    {
        return 1;
    }
}

sub valid_page
 {
 if (@okaydomains == 0) {return;}
  $DOMAIN_OK=0;                                         
  $RF=$ENV{'HTTP_REFERER'};                             
  $RF=~tr/A-Z/a-z/;                                     
  foreach $ts (@okaydomains)                            
   {                                                    
     if ($RF =~ /$ts/)                                  
      { $DOMAIN_OK=1; }
   }                                                    
   if ( $DOMAIN_OK == 0)                                
     { print "Content-type: text/html\n\n Sorry, cant run it from here:$RF";    
      exit;
     }                                                  
}


##################################################################
sub test_sendmail
 {
  @ts=split(/ /,$MAIL_PROGRAM);
  if ( -e $ts[0] )
   {
    return;
   }
   print "Content-type: text/html\n\n";
   print "<H2>$ts[0] NOTFOUND. PLEASE CHECK YOUR SCRIPT'S MAIL_PROGRAM VARIABLE</H2>";
   exit;
 }

sub do_log
{
open (ZL,">>$LOGFILE");
$date=localtime(time);
for ($i=1;$i<$MAXNUM+1;$i++)
    {
      $recipname="recipname_$i";
      $recipemail="recipemail_$i";
      if ($fields{$recipemail} eq "")
        {
         next;
        }
      if (&valid_address == 0)
        {
         next;
        }
     $logline="$date\|$JUMP_TO\|$fields{'send_email'}\|$fields{$recipemail}\|\n";
     print ZL $logline;
   }
  close(ZL);
}

###################################################################
###################################################################
sub sendmail  {

# error codes below for those who bother to check result codes <gr>

# 1 success
# -1 $smtphost unknown
# -2 socket() failed
# -3 connect() failed
# -4 service not available
# -5 unspecified communication error
# -6 local user $to unknown on host $smtp
# -7 transmission of message failed
# -8 argument $to empty
#
#  Sample call:
#
# &sendmail($from, $reply, $to, $smtp, $subject, $message );
#
#  Note that there are several commands for cleaning up possible bad inputs - if you
#  are hard coding things from a library file, so of those are unnecesssary
#

    my ($fromaddr, $replyaddr, $to, $smtp, $subject, $message) = @_;

    $to =~ s/[ \t]+/, /g; # pack spaces and add comma
    $fromaddr =~ s/.*<([^\s]*?)>/$1/; # get from email address
    $replyaddr =~ s/.*<([^\s]*?)>/$1/; # get reply email address
    $replyaddr =~ s/^([^\s]+).*/$1/; # use first address
    $message =~ s/^\./\.\./gm; # handle . as first character
    $message =~ s/\r\n/\n/g; # handle line ending
    $message =~ s/\n/\r\n/g;
    $smtp =~ s/^\s+//g; # remove spaces around $smtp
    $smtp =~ s/\s+$//g;

    if (!$to)
    {
	return(-8);
    }

 if ($SMTP_SERVER ne "")
  {
    my($proto) = (getprotobyname('tcp'))[2];
    my($port) = (getservbyname('smtp', 'tcp'))[2];

    my($smtpaddr) = ($smtp =~
		     /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
	? pack('C4',$1,$2,$3,$4)
	    : (gethostbyname($smtp))[4];

    if (!defined($smtpaddr))
    {
	return(-1);
    }

    if (!socket(MAIL, AF_INET, SOCK_STREAM, $proto))
    {
	return(-2);
    }

    if (!connect(MAIL, pack('Sna4x8', AF_INET, $port, $smtpaddr)))
    {
	return(-3);
    }

    my($oldfh) = select(MAIL);
    $| = 1;
    select($oldfh);

    $_ = <MAIL>;
    if (/^[45]/)
    {
	close(MAIL);
	return(-4);
    }

    print MAIL "helo $SMTP_SERVER\r\n";
    $_ = <MAIL>;
    if (/^[45]/)
    {
	close(MAIL);
	return(-5);
    }

    print MAIL "mail from: <$fromaddr>\r\n";
    $_ = <MAIL>;
    if (/^[45]/)
    {
	close(MAIL);
	return(-5);
    }

    foreach (split(/, /, $to))
    {
	print MAIL "rcpt to: <$_>\r\n";
	$_ = <MAIL>;
	if (/^[45]/)
	{
	    close(MAIL);
	    return(-6);
	}
    }

    print MAIL "data\r\n";
    $_ = <MAIL>;
    if (/^[45]/)
    {
	close MAIL;
	return(-5);
    }

   }

  if ($SEND_MAIL ne "")
   {
     open (MAIL,"| $SEND_MAIL");
   }

    print MAIL "To: $to\n";
    print MAIL "From: $fromaddr\n";
    print MAIL "Reply-to: $replyaddr\n" if $replyaddr;
    print MAIL "X-Mailer: Perl Powered Socket Mailer\n";
    print MAIL "Subject: $subject\n\n";
    print MAIL "$message";
    print MAIL "\n.\n";

 if ($SMTP_SERVER ne "")
  {
    $_ = <MAIL>;
    if (/^[45]/)
    {
	close(MAIL);
	return(-7);
    }

    print MAIL "quit\r\n";
    $_ = <MAIL>;
  }

    close(MAIL);
    return(1);
}
