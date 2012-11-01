#!/usr/bin/perl -w
#!perl -w


#FIXME - Add Error Checking

use CGI;
$q = CGI::new();

$number = $q->param("number");
$number =~s/\s+//g;
$number = uc($number);
$FORM = "Convert the character defined by HEX Digits: <form><input name=number value='$number'>" . 
"<input type=submit name=conv1 value='UTF8 to UTF16'><input type=submit name=conv2 value='UTF16 to UTF8'><input type=submit name=conv2 value='ISO LATIN-1(8859-1) to UTF8'>" . 
"</form><small>Note: you can look up entity references at <a href=http://www.w3.org/TR/REC-html40/sgml/entities.html>http://www.w3.org/TR/REC-html40/sgml/entities.html</a>";

print $q->header();
print $FORM, "<hr>";

#print "GOT $number with command", $q->param("conv1"), " and ", $q->param("conv2"),"<br>";
#UTF8 to UTF16
if ($q->param("conv1"))
{
	if (validUTF8($number))
	{
		$utf16 = 0;

		$dec = hex($number);
		$bin = dec2bin($dec);
		while (length($bin) < 24)
		{
			$bin = "0" . $bin;
		}
		if (length($number) == 2)
		{
			#format is 0xxxxxxxx
			$utf16bin = $bin;
			$utf16dec = bin2dec($utf16bin);
		        $utf16hex = uc(sprintf("%x",$utf16dec));	
		}
		elsif (length($number) == 4)
		
		{
			#                 00000000 0011111 111112222
			#                 01234567 89012345 67890123
			#                 -------- -------- --------          
			#format is        00000000 110yyyyy 10xxxxxx
			#Need to make it           00000yyy yyxxxxxx
			$x = substr($bin,18,6);
			$y = substr($bin,11,5);
			$utf16bin = $y . $x;
			$utf16dec = bin2dec($utf16bin); 
			#print "<b>bin=$bin x=$x y=$y utf16bin=$utf16bin utf16dec=$utf16dec</b><br>";
		        $utf16hex = uc(sprintf("%x",$utf16dec));	
		}
		elsif (length($number) == 6)
		{
			#                 00000000 0011111 111112222
			#                 01234567 89012345 67890123
			#                 -------- -------- --------          
			#format is        1110zzzz 10yyyyyy 10xxxxxx
			#Need to make it           zzzzyyyy yyxxxxxx
			$x = substr($bin,18,6);
			$y = substr($bin,10,6);
			$z = substr($bin,4,4);
			$utf16bin = $z . $y . $x;
			$utf16dec = bin2dec($utf16bin); 
			#print "<b>bin=$bin x=$x y=$y z=$z utf16bin=$utf16bin utf16dec=$utf16dec</b><br>";
		        $utf16hex = uc(sprintf("%x",$utf16dec));	
		}
		else
		{
			print "<font color=red>The binary string '$number' has invalid length=",length($number);
		print " Valid examples include '65', 'E39D8A', 'E3 9D 8A', 'C2A2', 'C2 A2', etc.";
			exit;
		}
		#print "UTF8 bytes $number as UTF-16 is: $utf16hex The character looks like this: &#x" . $utf16hex . ";";
		print htmlTable($number,$utf16hex);
		
		
	}
	else
	{
		print "<font color=red>$number is not a valid UTF8 string. Valid examples include '65', 'E39D8A', 'E3 9D 8A', 'C2A2', 'C2 A2', etc.";
		exit;
	}
}

######################## UTF-16 to UTF-8 ##############################
elsif ($q->param("conv2"))
{
	if (validUTF16($number))
	{
		$dec = hex($number);
		$bin = dec2bin($dec);
		while (length($bin) < 16)
		{
			$bin = "0" . $bin;
		}
		if ($bin =~ /^000000000/)
		{
			#                          0000000  00111111
			#                          01234567 89012345
			#                 -------- -------- --------          
			#format is                 00000000 0xxxxxxx
			#need to make              00000000 0xxxxxxx
			$utf8dec = bin2dec($bin); 
			#print "<b>bin=$bin x=$x y=$y utf8bin=$utf8bin utf8dec=$utf8dec</b><br>";
		        $utf8hex = uc(sprintf("%x",$utf8dec));	
		}
		elsif ($bin =~ /^00000/)
		{
			#                          0000000  00111111
			#                          01234567 89012345
			#                 -------- -------- --------          
			#format is                 00000yyy yyxxxxxx
			#need to make              110yyyyy 10xxxxxx
			$x = substr($bin,10,6);
			$y = substr($bin,5,5);
			$utf8bin = "110" . $y . "10" . $x;
			$utf8dec = bin2dec($utf8bin); 
			#print "<b>bin=$bin x=$x y=$y utf8bin=$utf8bin utf8dec=$utf8dec</b><br>";
		        $utf8hex = uc(sprintf("%x",$utf8dec));	
		}
		else
		{
			#                          0000000  00111111
			#                          01234567 89012345
			#                 -------- -------- --------          
			#format is                 zzzzyyyy yyxxxxxx
			#need to make     1110zzzz 10yyyyyy 10xxxxxx
			$x = substr($bin,10,6);
			$y = substr($bin,4,6);
			$z = substr($bin,0,4);
			$utf8bin = "1110" . $z . "10" . $y . "10" . $x;
			$utf8dec = bin2dec($utf8bin); 
			#print "<b>bin=$bin x=$x y=$y z=$z utf8bin=$utf8bin utf8dec=$utf8dec</b><br>";
		        $utf8hex = uc(sprintf("%x",$utf8dec));	
		}
		#print "UTF-16 bytes $number as UTF-8 is: $utf8hex The character looks like this: &#x" . $number . ";";
		print htmlTable($utf8hex,$number);
		
	}
	else
	{
		print "<font color=red>$number is not a valid UTF-16 string. Valid examples include '65', '9D8A', '9D 8A', '2', etc.";
		exit;
	}
}
else
{
}

sub validUTF16
{
	my $val = shift;
	if (length($val) > 4) {return 0;}
	if (length($val) <= 0) {return 0;}
	if (!( $val =~ /^[A-F0-9]+$/))
	{
		return 0;
	}
	return 1;
}
sub validUTF8
{
	my $val = shift;
	if (length($val) > 6) {return 0;}
	if (length($val) <= 0) {return 0;}
	if (!( $val =~ /^[A-F0-9]+$/))
	{
		return 0;
	}
	return 1;
}
sub dec2bin {
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
}

sub bin2dec{
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub bin2hex{
    return sprintf ("%x",bin2dec(shift));
}

sub htmlTable{
	my $utf8 = shift;
	my $utf16 = shift;
	while (length($utf16) < 4)
	{
		$utf16 = "0" . $utf16;
	}
	return "<table border><tr><th>UTF-8<th>UTF-16<th>Character<tr><td>$utf8<td>$utf16<td>&#x" . $utf16 . ";</table>";
}



