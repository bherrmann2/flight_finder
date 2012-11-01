#!/usr/bin/perl -w
#
#
# Date        name     version Comment
#------------ -------- ------- ---------------------------------------------
# 30 JUL 2008 jwerwath 12      send healthcheckserver alerts to n_hosting
use CGI;
$q = new CGI;

$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f webform@wimkp.org';
$VERSION = 12;
print $CONTENT_TYPE;

#---------------------------- Hack to send healthcheckserver msgs to n_hosting
$TO = $q->param("to");
if ($q->param("subject") =~ /^healthcheckserver error/)
{
        $TO = $TO . "," . "Hosting_Alerts\@novarra.com";
}
#----------------------------------- end hack
if ($q->param("to"))
{
  if (
     ($q->param("to") =~ /novarra/i) 
     || ($q->param("to") =~ /werwath/) 
     || ($q->param("to") =~ /jason/i) 
     || ($q->param("to") =~ /wisti/i) 
     || ($q->param("to") =~ /scissorsoft/i)
     || ($q->param("to") =~ /8474775615/i)
     || ($q->param("to") =~ /8477083756/i)
     || ($q->param("to") =~ /6303911743/i)
     )
	{
	#were ok
	}
	else
	{
	  print "ERROR: Unauthorized email address.  mail not sent.";
		exit(0);
	}
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
print "<form method=post>To:<input name=to value=werwath\@hotmail.com><br>From:<input name=from value=jwerwath\@novarra.com><br>Subject:<input name=subject value=foo><br>Message:<textarea name=msg>bar</textarea><input type=submit value=Send></form>";
}

print "Done.  (version $VERSION)";


sub getMail
{
$mail = "";
$mail .= "To: ". $TO . "\n";
$mail .= "From: ". $q->param("from") . "\n";
$mail .= "Cc: jwerwath\@novarra.com\n";
$mail .= "Subject:" . $q->param("subject") . "\n";
$mail .= "\n\n";
$mail .=  getMessage() . "\n\nThank you " . $q->param("to") .".  Questions or Comments ?  Please email Jim Werwath (jim\@scissorsoft.com)\n";
$mail .= "(version $VERSION) \n";
return $mail;
}

sub getMessage
{
  
	#[NAME:nwebs ver. 6.6.6 Samsung A900 nocache CHUNK=526] [dj80hd.com CON=12434 NET=753 HTP=1111 IMT=6 IMN=87 IMP=0 PNT=1408 TOT=16600 BYT=4380 MEM=347] [lp.org CON=5909 NET=1961 HTP=9208 IMT=107 IMN=1267 IMP=2 PNT=1830 TOT=22132 BYT=25896 MEM=272]
  #KEY: CON:MakeConnectionTime NET:HTMLNetworkTime HTP:HTMLProcessingTime IMT:CreateImageTrTime IMN:IMageNetworkTime IMP:ImageProcessingTime PNT:PaintTime TOT:PageTotalTime BTS:mTotalBytes

  if (($q->param("subject") =~ /Profile Load/) || ($q->param("subject") =~ /^APL:/))
  {
	    my $msg = $q->param("msg");
			my $name = "";
			my $chunk = "";
			my $line = "";
			my $newmsg = 
			"------- Begin Excel Data -------\n" .
			"name,date (in epoch seconds),max chunk size (in K), url, Connection Time, Network Time, HTML processing Time, Image Transation Time, Image Network Time, Image Processing Time, Paint Time, Total Time, Total Bytes, Free Memory(In K),chunks\n\n"
			;
	    $_ = $msg;
			#MATCH each set of brackets
			@parts = m/\[[^\]]+\]/g;
			if ($#parts < 2)
			{
			  return "ERROR (101): Could not decode message.\n" . $msg;
			}
			
			$count = $#parts; 
      for ($i=0; $i<=$count; $i++)
      {
	      $line = $parts[$i];
	      #print "LINE:$line i=$i"."\n";
	      if ($i == 0)
	      {
		      $line =~/\[NAME:(.*)\s+CHUNK=(\d+)\]$/;
				  if (!$1 || !$2)
				  {
				   return "ERROR (102): Could not decode name.\n" . $msg;
				  }
		      $name = $1;
		      $chunk = $2;
		
	      }
	      else
	      {
				
				 		if ($line =~ /^\[(\S+)\s+CON=(\d+) NET=(\d+) HTP=(\d+) IMT=(\d+) IMN=(\d+) IMP=(\d+) PNT=(\d+) TOT=(\d+) BYT=(\d+) MEM=(\d+) CHK=(\S+)/)
						{
						   #do nothing
						}
            elsif ($line =~ /^\[(\S+)\s+CON=(\d+) NET=(\d+) HTP=(\d+) IMT=(\d+) IMN=(\d+) IMP=(\d+) PNT=(\d+) TOT=(\d+) BYT=(\d+) MEM=(\d+)/)
						{
						   #do nothing
						}
            else
						{
						  return "ERROR (103): Could not parse this line.\n$line\n\n" . $msg;
				    }
		        $line2add = "$name," . time . ",$chunk,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12\n";
					  $newmsg .= $line2add;
				}#end if-else
			}#end for ($i=0; $i<$#parts; $i++)
			$newmsg .= "----------End Excel Data -------\n\n";
			
			$newmsg .= "----------Begin Original Data From Client -------\n";
			$newmsg .= $msg;
			$newmsg .= "\n------------End Original Data From Client -------\n";
      return $newmsg;
  }#endif ("Automated Profile Load" eq $q->param("subject"))
	
  
  else
	{
	  return $q->param("msg");
	}
}#getMsg

