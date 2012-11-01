#!/usr/bin/perl
#!perl
#!/usr/bin/perl



#
# TODO
# * if a site has both wap.gov.com and wml.gov.com and neither is wml format
# then do not add these to the mobile sites.
#
# * Try hitting the site with a WML only UA and see if content comes back
# as WML.  If so, the main url (e.g. www.wapsexy.com) is also a wireless site
#
#

require LWP::UserAgent;
use CGI;
$DEBUG = 0;
$MAX_WIRELESS_SITE_BYTES = 64000;

$DB_FILENAME = "mobileSiteData.txt";
@DB_LINES = ();
$SEPARATOR = "___SEP___";

$q = new CGI;
$form = "";


$url = $q->param("url");


$check = $q->param("check");
$go = $q->param("go");

#Just redirect if nothing else to do...
if (0)#($go && ($check ne "checked"))
{
	print $q->redirect($url);
}
else 
{
  @DB_LINES = &getFileLines($DB_FILENAME) || print "Could not open file $DB_FILENAME";
	print "Content-Type: text/html\n\n";
	$form .= "<form action=findmobilesite.pl>Keyword (e.g. google)<input size=40 name=url value='$url'><input type=submit name=go value=Go><br>";
	$form .= "<input type=checkbox name=check value=checked>Force a database update for this site. (takes longer !)";
	$form .= "</form>";
	if (!$url) 
{
	 print $form;
		exit();
}
	#print $form;
	if ($url =~ /^\S+$/)
	{
	 	 $url = "http://www." . $url . ".com";
	}
	if (!($url =~ /^http:/))
	{
	 $url = "http://" . $url;
	}
	if ($url =~ /^http:\/\/.*\.(\w+)\.(net|com|org|co\.uk)/)
	{
		$host = $1 . "." . $2 . "/";
	}
	elsif ($url =~ /^http:\/\/(\w+)\.(net|com|org|co\.uk)/)
	{
		$host = $1 . "." . $2 . "/";
	}
	elsif ($url eq "http://")
	{
	  print $form;
		exit();
	}
	else
	{
		print "<b>No url entered. url=$url</b><br>";
		&debug("<hr>" . &file2Html($DB_FILENAME));
		exit();
	}
	@mobileUrls = &getMobileSites($host);
	
	#If the user forces a check, do it.
	#Also check if nothing is in the database.
	if ($check eq "checked" || (!@mobileUrls))
	{
	#NOTE: $host MUST end in a slash !!! (/) 
	@urls2try = ("http://wap." . $host, "http://mobile." . $host, "http://wml." . $host,
		"http://www." . $host . "mobile/", 
		"http://www." . $host . "wml/", 
		"http://www." . $host . "wap/");
       foreach $u (@urls2try)
	{
		$results = &testUrl($u);
		if ($results->{"VALID"})
		{
			print "<a href=$u>$u</a> IS VALID " . $results->{"SIZE"} . " bytes of " . $results->{"CT"} . "<br>" unless (!$DEBUG);
			if ($results->{"SIZE"} > $MAX_WIRELESS_SITE_BYTES)
			{
				print "TO BIG !<br>" unless (!$DEBUG);
			}
			elsif ($results->{"SIZE"} <= 0)
			{
				print "NO CONTENT!<br>" unless (!$DEBUG);
			}
			else
			{
			  &addMobileSite($host,$u);
				push (@mobileUrls, $u);
			}
		}
		else
		{
			print "$u IS <b>NOT</b> VALID <br>" unless (!$DEBUG);
		}
		
	}#end foreach mobile URl to try
	if (!@mobileUrls)
		{
		   #put this here so it is noted in the database that we already seached for it.
		 	 &addMobileSite($host,"NONE");
		}
	}
	
	
	$hasMobile = 0;
	if (@mobileUrls)
	{
		#FIXME - save these to a database
		print "<b>Mobile Site(s):</b><br>";
		foreach $mobileUrl (@mobileUrls)
		{
		  if ($mobileUrl ne "NONE")
			{
			 	 print "<a href=$mobileUrl>$mobileUrl</a><br>";
				 $hasMobile = 1;
			}
		}
	}
	if (!$hasMobile)
	{
		print "There are no known mobile sites for this url.<br>";
	}	
	print "<br><b>Main Site:</b><br><a href=$url>$url</a>";
	print "<br>$form";
	&debug("<hr>" . &file2Html($DB_FILENAME));
}

sub testUrl
{
my $results = {};
my $u = shift;
my $ua = LWP::UserAgent->new(env_proxy => 1,
                              keep_alive => 1,
                              timeout => 30,
                             );
$ua->agent('Mozilla/5.0');
$request = HTTP::Request->new('GET', $u);

$response = $ua->request($request); # or
$ct = $response->content_type;
$results->{"VALID"} = $response->is_success;
&debug("SUCCESS:" . $results->{"VALID"});
$results->{"CT"} = $response->content_type;
&debug("CT:" . $results->{"CT"});
$results->{"SIZE"} = length( $response->content);
&debug("SIZE:" . $results->{"SIZE"});
return $results;
#print "$u: <i>$ct</i><br>";
#return $response->is_success;
#$data =  $response->content;
#$data =~ s/</&lt;/g; 
#$data =~ s/>/&gt;/g; 
#print "<hr><pre>$data</pre><hr>";
}

sub addMobileSite
{
 		my $host = shift;
		my $site = shift;
		my $line = $host . $SEPARATOR .  $site;
		my $exists = grep (/$line/,@DB_LINES);
		if ($exists)
		{
		 	 &debug("NOT ADDING LINE $line because it is there: $exists ". join(',',@DB_LINES));
		}
		else
		{
		    $line = &cleanString($line);
		 		&appendToFile($line, $DB_FILENAME);
		}
		
}#addMobileSite

#Returns an array of mobile sites for a given host
sub getMobileSites
{
  my @ret = ();
	my $host = shift;
	@ss = grep(/^$host/,@DB_LINES);
	foreach $dbline (@ss)
	{
	 				
	 				($h,$s) = split(/$SEPARATOR/,$dbline);
					$s = &cleanString($s);
					&debug("getMobileSites checking $dbline with $host got $h and $swith SEP $SEPARATOR");
					
					push @ret, $s;
	}
	
	return @ret;
	#FORMAT is host<SEPARATOR>mobileurl1<SEPARATOR>mobileurl2 ...etc
	
}#getMobileSites

sub appendToFile
{
	my $what = shift;
	my $fname = shift;
	my $openfilecmd = ">$fname";
	if (-e $fname)
	{
	 	 my $openfilecmd = ">>$fname";
	}
	if (open(F,">>$fname"))
	{
		print F $what . "\n";
		close F;
		&debug("Appended the following to $fname:<br>" . $what);
	}
	else
	{
		&debug ("<h2>Oops: appendToFile $fname $! </h2>");
	}
}
sub getFileLines
{
  my @ret = ();
  $filename = shift;
	if (-e $filename)
	{
  open (F,$filename);
  @lines = (<F>);
  close F;
	}
	else
	{
	&debug("file does not exist:$filename");
	}
	return @lines;
}#getLines

sub debug
{
my $s = shift;
print "$s<br>\n" unless (!$DEBUG);
}
sub file2Html
{
	my $fname = shift;
	if (open (F,$fname))
	{
		@flines = (<F>);
		close F;
		return "<pre>" . join ("",@flines) . "</pre>";
		#return "<textarea>" . join ("",@flines) . "</textarea>";
	}
	else
	{
		return "Error: $fname could not be read $!";
	}
}
sub cleanString
{
my $s = shift;
$s =~ s/^\s+//;
$s =~ s/\s+$//;
return $s;
}
