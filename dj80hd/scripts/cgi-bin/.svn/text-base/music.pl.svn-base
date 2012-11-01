#!/usr/bin/perl 
use CGI;
$q = new CGI;
$DO_MAIL = 0;
$ALLTXT = "all.txt";
$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f webform@wimkp.org';
$VERSION = 2.2;
$WISHLIST_URL = 'http://www.amazon.com/gp/registry/wishlist/1461UAKXRULJT?reveal=unpurchased&filter=all&sort=date-added&layout=compact&x=12&y=12';
$FILE_LIMIT = 20;
$MAX_OPTION_LENGTH = 180;
#
#
# 14-Mar-2008 2.0 File limit, Max length option limit
# 25-Mar-2008 2.1 Search alert email
# 18-AUG-2008 2.2 No max for werwath@gmail.com
#

@lines = (); #hacky global for performance.
@matches = (); #hacky global for performance.

$terms = $q->param("terms");
$search_made = ($terms && ($q->param("action") eq "Search"));
if ($terms eq "___ALL___") {
  print "Content-type: text/plain\n\n";
  open(F,$ALLTXT);
  while (defined ($line =<F>) ) {
    print $line;
  }
  close F; 
  exit;
}

print $CONTENT_TYPE;
print "<html><body>\n<h1><i>dj80hd music search version $VERSION</i></h1>\n";
if ($search_made)
{
  if (open(F,$ALLTXT))
  {
    @lines = (<F>); 
  }
  else
  {
    print "<h3>ERROR! COULD NOT OPEN DATA FILE </h3>"; exit;
  }
  #Check valid terms.
  if (&valid_terms($terms))
  {
    @matches = &get_matches($terms);
       
  }
  else
  {
    print "<h3><font color=red>The following search terms you entered were not valid.  They must be alphanumeric words seperated by spaces: '" . $terms . "'</font></h3>";
  }
}
elsif ($q->param("action") eq 'Make Request')
{
  $email = $q->param("email");
  $pass = $q->param("xxx");
  @files = $q->param("files");
  if ($pass ne "kerry4")
  {
    print "SORRY THAT IS THE WRONG PASSWORD !"; exit;
  }
  if (!$email)
  {
    print "You forgot to enter your email !";   exit;
  }
  if (!($email =~ /^[.@\w]+$/))
  {
    print "This email is invalid: " . $email;   exit;
    }
  if ($#files < 0)
  {
     print "You forgot to select files !";   exit;
  }
  if ($#files >= $FILE_LIMIT && ($email ne 'werwath@gmail.com') )
  {
     print "I'm sorry, the maximum number of files is $FILE_LIMIT!";   exit;
  }
  
  #Ensure this is safe for piping to sendmail !!! 
  #my $msg = "I WANT THESE FILES\n" . join("\n",@files) . "\n" . $q->param("special");
  my $msg = "I WANT THESE FILES\n" . join("\n",@files) . "\n" ;
  #print "MAIL:<PRE>" . get_mail($msg) . "</PRE>";
  $mail = &get_mail($msg, "I WANT THESE FILES");
  &send_mail($mail);
  #If we got here we have a success
  print "This request was sent:<br><pre>" . $msg . "</pre>\n";
  print "<br><h4><blink><font color=red>NOTE: Requests can take up to 48 hours to fill !</font></blink></h4>\n";
}
else
{
   
	#print "GOT INVALID PARAMETERS!";
}

$form1 = "<form action=/cgi-bin/music.pl>Search For: <input name=terms><input type=submit value='Search'><input type='hidden' name='action' value='Search'></form>\n" . 
"<br><br><i><small>Note: search terms must be alpha numeric terms seperated by spaces e.g. 'Justice Remix'</small></i>";

$form2 = "";
$num_matches = $#matches + 1;
if ($search_made)
{
  $form2 = $form2 . "NUMBER OF MATCHES : " . $num_matches;
  $form2 = $form2 . " (try <a href=/cgi-bin/mixwit.pl>the mixwit search</a>)" unless ($num_matches > 0);
  $form2 = $form2 . "<br>\n";

}

if ($num_matches > 0 && $search_made)
{
  $form2 = $form2 . "\n<form action=music.pl method=post><select multiple name=files>" . &get_options(@matches) . "</select>" . "<br>Select the files you want above and fill out this form:<br>Your email address: <input name=email><br>The secrect password: <input name=xxx>" . 
  #"<br>Special instructions:<input name=special>" . 
  "<br><input name=action type=submit value='Make Request'></form>";
}
else
{
}
print $form1, "<hr>", $form2;
#print "\n<hr>The whole list is available <a href=http://scissorsoft.com/all.zip>here</a>.\n";
#print "<b>Please help me.  Do you have <a href=http://www.amazon.com/gp/registry/wishlist/1461UAKXRULJT/ref=lst_llp_wl-go>CDs or lossless copies of these ?</a></b> \n";
print "<b>Do you have <a target=_blank href=$WISHLIST_URL>CDs or lossless copies of these ?</a></b> \n";

#
#if ($search_made)
#{
#  $mail = &get_mail("Search for '" . $terms . "' from " . $q->referer() . " " . $q->remote_addr(), "SEARCH FOR $terms");
#  &send_mail($mail);
#}


sub valid_terms
{
  my $terms = shift;
  return ($terms =~ /^[ \w]+$/);
}

sub get_options
{
  my $out = "";
  my @matches = @_;
  foreach (@matches)
  {
    s/"/&quot;/g;

    $out = $out . "<option value=\"" . $_ . "\">" . $_ . "</option>\n" unless (length($_) > $MAX_OPTION_LENGTH);
  }
  return $out;
}#get_options


sub get_matches
{
  my $terms = shift;
  my @words = split(' ',$terms);
  #print "WORDS ARE " . join('---',@words);
  my @matches = ();
  foreach $line (@lines)
  {
    $ok = 1;
    foreach $word (@words)
    {
      $ok = $ok && ($line =~ /$word/i);
      next if !$ok;
    }#foreach word
    push (@matches,$line) unless !$ok;
  }#foreach $line
  return @matches;
}#get_matches

sub send_mail
{
  my $mail = shift;
  if( open(MAIL,"|$SENDMAIL -t"))
   {
     print MAIL $mail;
     close(MAIL);
   }
   else
   {
      print "ERROR: Mail not sent $!"; exit;
   }
}
sub get_mail
{
my $msg = shift;
my $subject = shift;
my $mail = "";
$mail .= "To: ". "jim\@scissorsoft.com" . "\n";
$mail .= "From: ". $q->param("email") . "\n";
$mail .= "Cc: jwerwath\@novarra.com\n";
$mail .= "Subject:" . $subject . "\n";
$mail .= "\n\n";
$mail .=  $msg . "\n\nThank you " . $q->param("to") .".  Questions or Comments ?  Please email Jim Werwath (jim\@scissorsoft.com)\n";
$mail .= "(version $VERSION) \n";
return $mail;
}
#
