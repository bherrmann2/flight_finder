#!/usr/bin/perl -w

#
##
#
# 03 SEP 2008 jwerwath  Ported this from t50 because t50 was not working.
#

use CGI;
$q = new CGI;

$CONTENT_TYPE = "Content-type: text/html\n\n";
$SENDMAIL = '/usr/lib/sendmail -f apl@scissorsoft.com';
$VERSION      = 10;
print $CONTENT_TYPE;

if ($q->param("to")) {
  if (($q->param("to") =~ /novarra/i) || ($q->param("to") =~ /werwath/)) {
	#were ok
	 } else 	{
		  print "ERROR: Unauthorized email address.  mail not sent.";
			exit(0);
	 }

	 if( open(MAIL,"|$SENDMAIL -t")) {
		 print MAIL getMail();
		 close(MAIL);
		 print "This was piped to $SENDMAIL -t: <br>", getMail();
		 print "<hr><a href=\"mailtest.pl\">AGAIN</a><hr>";
	 } else {
		print "ERROR: Mail not sent !";
	 }
} else {
	print "<form method=post>\n";
	print "<table>\n";
	print "<tr><td>To:</td>     <td><input name=to value=engineer\@novarra.com></td></tr>\n";
	print "<tr><td>From:</td>   <td><input name=from type=hidden value=t50\@novarra.net>t50\@novarra.net</td></tr>\n";
	print "<tr><td>Subject:</td><td><input name=subject value=foo></td></tr>\n";
	print "<tr><td>Message:</td><td><input name=msg value=bar></td></tr>\n";
	print "<tr><td colspan=2><input type=submit value=Send></td></tr>\n";
	print "</table>\n";
	print "</form>\n";
}

print "Done.  (version $VERSION)";


sub getMail
{
$mail = "";
$mail .= "To: ". $q->param("to") . "\n";
$mail .= "From: ". $q->param("from") . "\n";
$mail .= "Cc: jwerwath\@novarra.com\n";
$mail .= "Subject:" . $q->param("subject") . "\n";
$mail .= "\n\n";
$mail .=  getMessage(); # . "\n\nThank you " . $q->param("to") .".  Questions or Comments ?  Please email Jim Werwath (jim\@scissorsoft.com)\n";
$mail .= "\n(version $VERSION) \n";
return $mail;
}



#
# Get message formulates the email text to be sent.
# this implements the AUTOMATED_PROFILE_LOAD feature
# (j2me/midp/featureDocumentation/AUTOMATED_PROFILE_LOAD.html)
# 
# The following is a sample of an AUTOMATED_PROFILE_LOAD email:
#
#
#------- Begin Excel Data -------
#name,date (in epoch seconds),max chunk size (in K), url, Connection Time, Network Time, HTML processing Time, Image Transation Time, Image Network Time, Image Processing Time, Paint Time, Total Time, Total Bytes, Free Memory(In K),chunks
#
#106e nwebx for 6630,1145037153,2193,www.google.com,2890,78,1749,31,32,0,109,5531,4014,1161,
#106e nwebx for 6630,1145037153,2193,http://test50.novarra.com/performance/cnn/www.cnn.com/index.htm,4891,296,6829,63,62,0,842,13640,49974,1165,
#106e nwebx for 6630,1145037153,2193,http://test50.novarra.com/performance/amazon.co.uk/amazon.co.uk/default.htm,3640,346,9388,156,2359,0,2843,19469,94880,825,
#106e nwebx for 6630,1145037153,2193,msnbc.com,7687,313,6015,312,141,0,2608,17016,31706,801,
#----------End Excel Data -------
#
#----------Begin Original Data From Client -------
#[NAME:106e nwebx for 6630 CHUNK=2193]
#[www.google.com CON=2890 NET=78 HTP=1749 IMT=31 IMN=32 IMP=0 PNT=109 TOT=5531 BYT=4014 MEM=1161] [http://test50.novarra.com/performance/cnn/www.cnn.com/index.htm CON=4891 NET=296 HTP=6829 IMT=63 IMN=62 IMP=0 PNT=842 TOT=13640 BYT=49974 MEM=1165] [http://test50.novarra.com/performance/amazon.co.uk/amazon.co.uk/default.htm CON=3640 NET=346 HTP=9388 IMT=156 IMN=2359 IMP=0 PNT=2843 TOT=19469 BYT=94880 MEM=825] [msnbc.com CON=7687 NET=313 HTP=6015 IMT=312 IMN=141 IMP=0 PNT=2608 TOT=17016 BYT=31706 MEM=801]
#KEY: CON:MakeConnTime NET:HTMLNetTime HTP:HTMLProcTime IMT:CreateImgTrTime IMN:ImgNetworkTime IMP:ImageProcime PNT:PaintTime TOT:PageTotTime BYT:TotBytes MEM=FreeMemK
#
#------------End Original Data From Client -------
#
#
sub getMessage
{
  
	#[NAME:nwebs ver. 6.6.6 Samsung A900 nocache CHUNK=526] [dj80hd.com CON=12434 NET=753 HTP=1111 IMT=6 IMN=87 IMP=0 PNT=1408 TOT=16600 BYT=4380 MEM=347] [lp.org CON=5909 NET=1961 HTP=9208 IMT=107 IMN=1267 IMP=2 PNT=1830 TOT=22132 BYT=25896 MEM=272]
  #KEY: CON:MakeConnectionTime NET:HTMLNetworkTime HTP:HTMLProcessingTime IMT:CreateImageTrTime IMN:IMageNetworkTime IMP:ImageProcessingTime PNT:PaintTime TOT:PageTotalTime BTS:mTotalBytes

	#if this is the subject of an AUTOMATED_PROFILE_LOAD email...
  if (($q->param("subject") =~ /Profile Load/) || ($q->param("subject") =~ /^APL:/))
  {
	    my $msg = $q->param("msg");
			my $name = "";
			my $chunk = "";
			my $line = "";
			my $newmsg = 
			"------- Begin Excel Data -------\n" .
			"name, device id, date (in epoch seconds),max chunk size (in K), url, Connection Time, Network Time, HTML processing Time, Image Transation Time, Image Network Time, Image Processing Time, Paint Time, Total Time, Total Bytes, Free Memory(In K), chunks, Server Timestamp, ContentServer HTML Time, ACA HTML Time, ContentServer Images Time, ACA Images Time\n\n"
			;
	    $_ = $msg;
			#MATCH each set of brackets
			@parts = m/\[[^\]]+\]/g;
			if ($#parts < 1)
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
		      $line =~/\[NAME:(.*)\s+DEVID=(\d+)\s+CHUNK=(\d+)\]$/;
				  if (!$1 || !$2 || !$3)
				  {
				   return "ERROR (102): Could not decode name.\n" . $msg;
				  }
		      $name = $1;
		      $devid = $2;
		      $chunk = $3;
		
	      }
	      else
	      {
	          # We need to remove commas for excel spreadsheet
	      	 $line =~ s/,//g;
	          if ($line =~ /^\[(\S+)\s+CON=(-{0,1}\d+) NET=(-{0,1}\d+) HTP=(-{0,1}\d+) IMT=(-{0,1}\d+) IMN=(-{0,1}\d+) IMP=(-{0,1}\d+) PNT=(-{0,1}\d+) TOT=(-{0,1}\d+) BYT=(-{0,1}\d+) MEM=(-{0,1}\d+) CHK=(\S+) STS=(.+) CHT=(-{0,1}\d+) AHT=(-{0,1}\d+) CIT=(-{0,1}\d+) AIT=(-{0,1}\d+)/)
				 	   {
				 			#do nothing
			    		}
				
				    #Data line that includes CHUNKS (this was added later)
				 elsif ($line =~ /^\[(\S+)\s+CON=(-{0,1}\d+) NET=(-{0,1}\d+) HTP=(-{0,1}\d+) IMT=(-{0,1}\d+) IMN=(-{0,1}\d+) IMP=(-{0,1}\d+) PNT=(-{0,1}\d+) TOT=(-{0,1}\d+) BYT=(-{0,1}\d+) MEM=(-{0,1}\d+) CHK=(\S+)/)
						{
						   #do nothing
						}
						#Old version that does not include chunks.
            elsif ($line =~ /^\[(\S+)\s+CON=(-{0,1}\d+) NET=(-{0,1}\d+) HTP=(-{0,1}\d+) IMT=(-{0,1}\d+) IMN=(-{0,1}\d+) IMP=(-{0,1}\d+) PNT=(-{0,1}\d+) TOT=(-{0,1}\d+) BYT=(-{0,1}\d+) MEM=(-{0,1}\d+)/)
						{
						   #do nothing
						}
            else
						{
						  return "ERROR (103): Could not parse this line.\n$line\n\n" . $msg;
				    }				  				  

		        $line2add = "$name," . "$devid," . time . ",$chunk,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17 \n";
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
