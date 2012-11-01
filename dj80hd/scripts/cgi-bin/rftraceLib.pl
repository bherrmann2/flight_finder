sub extractHexContentFromRFTRACE #(@rftraceLines)
{
	my @lines = @_;
	# ---
	# FORMAT IS 
	#      . . . . 5 . . . . 0 . . . . 5 . . . . 0 . . . . 5 . . . . 0 . .
	#0000 436F6E74656E742D547970653A20746578742F786D6C0D0A436F6E74656E742D     Content-Type: text/xml..Content-
	#0001 4C6F636174696F6E3A20687474703A2F2F6E6577732E66742E636F6D2F686F6D     Location: http://news.ft.com/hom
	#0002 652F756B0D0A4E6F76617272612D43616368652D436F6E74726F6C3A206D6178     e/uk..Novarra-Cache-Control: max
	#0003 2D6167653A20300D0A4E6F76617272612D506167652D49643A20313634393132     -age: 0..Novarra-Page-Id: 164912
	#0004 3132340D0A4E6F76617272612D5552493A20687474703A2F2F6E6577732E6674     124..Novarra-URI: http://news.ft
	#0005 2E636F6D2F0D0A436F6E74656E742D456E636F64696E673A20677A69700D0A4E     .com/..Content-Encoding: gzip..N
	#0006 6F76617272612D436F6E74656E742D4C656E6774683A2033373038350D0A436F     ovarra-Content-Length: 37085..Co
	#0007 6E74656E742D4C656E6774683A20353032380D0A0D0A1F8B0800000000000000     ntent-Length: 5028..............
	#0008 CD5DFD72DB38927F1514A76AAE6A6B6DEAFBE32ED69413C799CCC4D954ECA9D4     .].r.8....j.jkm............T...
	#0009 EE3F5B20094A1C938406202D6BFFBC27B967B97BB1EB06487DD8B269306DEDA4     .?[ .J.... -k..'.g.{...H}..i0m..
	#0010 62118024F0A7EE46A3D16834DFC820C85216702D164AC467DEA22896FFE9FBB9     b..$...F..h4.. .R.p-.J.g..(.....
	# ...
	#0163 1F7E6F879FC57DF1A0CFE9F7D1E187CFF2EE939CE34E80B9ECF56EA6D1EF418C     .~o...}..............N....n...A.
	#0164 BD5B3306AC7B73ADC4BF127B1904593AFB7F158E5A5DDD900000                 .[3..{s....{..Y:...Z]....      
	#
	#
	# First step is to gather up all the hex
	$allHex = "";
        foreach $line (@lines)
	{
		if ($line =~ /^\w{4,4}\s+(\w{2,64})\s+/)
		{
			#print $1, "\n";
			$allHex .= $1;
		}
	}

	#Next find the File Length:
	($head,$body) = split(/436F6E74656E742D4C656E6774683A20\d+0D0A0D0A/,$allHex);
	#//$allHex =~ /436F6E74656E742D4C656E6774683A20(\d+)0D0A0D0A/;
	#print "CONTENT LENGTH=" . &hexIntDigitsToInt($1) . "\n";
	#print "BODY IS " . length($body)/2 . " bytes\n";
	return $body;
	
}

#e.g. returns 5028 for 35303238
sub hexIntDigitsToInt
{
	$hex = shift; #e.g. 35303238 for 5028
	$int = 0;
	for ($i=0;$i<length($hex);$i++)
	{
		$i++; #skip the 3
		$int = ($int * 10 ) + substr($hex,$i,1);
	}
	return $int;
}
1;
