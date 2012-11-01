#!/usr/bin/perl

#--------------------------------------------------------------------
# TODO:                                                                
# - HTTPS: site support (www.fidelity.com)
# - Report 404 properly
# - Login
# - Favorites
# - Menu like config | favs | url | spy
#--------------------------------------------------------------------
use HTML::Parser();
use URI;
use CGI;
require LWP::UserAgent;

$SERVER_URL = "http://127.0.0.1:8888";
$SCRAPER_SCRIPT = "/cgi-bin/icbrowser.pl";
$IC_SCRIPT = "/pom/ic.php";      
$PRODUCTION = 1;
sub printHtmlMenu
{
	print "<a href=\"" . $SCRAPER_SCRIPT . "\">config</a> | ";
	print "<a href=\"" . $SCRAPER_SCRIPT . "\">favs</a> | ";
	print "<a href=\"" . $SCRAPER_SCRIPT . "\">browse</a> | ";
	print "<a href=\"" . $SCRAPER_SCRIPT . "\">spy</a>";
	print "<br/>";
}

$q = new CGI;
$url = $q->param("url");
	print "Content-Type: text/html\n\n";
	print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML Basic 1.0//EN\" \"http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd\" >\n";
	print "<html><body><p>\n";
	&printHtmlMenu();
if (!($url))
{
	&printHtmlForm();
	print "</body></html>";
	exit;
}
if (($ENV{"SERVER_PORT"} eq "8888") && ($ENV{"SERVER_ADDR"} eq "127.0.0.1"))
{
	$SERVER_URL = "http://127.0.0.1:8888";
}
else
{
	$SERVER_URL = "http://" . $ENV{"SERVER_NAME"};
}
#FIXME - make this work !

$x = $q->param("x");
$y = $q->param("y");
$miny = $q->param("miny");
$minx = $q->param("minx");

$x = 150 unless ($x);
$y = 150 unless ($y);
$minx = 30 unless ($minx);
$miny = 30 unless ($miny);

$linksOK = $q->param("linksOK");
	
	&printHtmlForm();
$currentHREF = "";
#print "<b><i>" . $url . "</i></b><br/>\n";
#$uri = URI->new_abs( $str, $base_uri )
# Create instance
$p = HTML::Parser->new(start_h => [\&start_rtn, 'tag, attr'],
                text_h => [\&text_rtn, 'text'],
                end_h => [\&end_rtn, 'tag']);

my $ua = LWP::UserAgent->new(env_proxy => 1,
                              keep_alive => 1,
                              timeout => 30,
                             );
			     $ua->agent('Mozilla/5.0');
$request = HTTP::Request->new('GET', $url);

$response = $ua->request($request); 
$content = $response->content;
# Start parsing the following HTML string
$p->parse($content);
print "</p></body></html>\n";

sub start_rtn 
{
	# Execute when start tag is encountered
    ($tag, $hashref) = @_;
    #print "===<br>\nStart: $tag<br>\n";
    if ($tag eq "img")
    {
	    $src = $hashref->{"src"};
	    $u = URI->new_abs( $src, $url );
	    $imageHtml = &ICImageHtml($u);
	    #print "<B>imageHtml=$imageHtml <br></B>";
	    print "SRC=" . $src . " <i>(" . &HTTPUnEscapeString(&ICImageURL($u)) . ")</i><br>" unless ($PRODUCTION);
	   print $imageHtml . "<br>\n" ;
	    print "HREF=" . $currentHREF unless ($PRODUCTION);
	    print "<br>" unless ($PRODUCTION);
	    print "IMG HTML=" . &HTML2TEXT($imageHtml) unless ($PRODUCTION);      
	    print "<hr>" unless ($PRODUCTION);
    }
    elsif ($tag eq "a")
    {
	    $href = $hashref->{"href"};
	    #$onclick = $hashref->{"onclick"};
	    #Known to match the following:
	    #javascript:openHTMLWindow('modelpop.php?model=470',%20500,%20690);
	    #javascript:openHTMLWindow('modelpop.php?model=426', 500, 690);
	    #javascript:popWin(
	    #print "a href=$href <br/>";
	    if ($href =~ /^javascript:/i)
	    {
		    #print "<BLINK>Got one:</BLINK>";
		if ($href =~ /[open]\S*\(\s*['|"](\S+)['|"].*\)/)
		{
			#print "<BLINK>$1</BLINK>";
			$href = $1;
		}
		else
		{
			#print "<BLINK>NO URL in $href<br></BLINK>";
		}
	    }
	    if ($href)
	    {
	    $currentHREF = URI->new_abs( $href, $url );
	    }
	}	    
    	elsif ($tag eq "frame")
    	{
	    $name = $hashref->{"name"};
	    $name = "frame" unless $name;
	    $src = $hashref->{"src"};
	    #print "<blink>got a frame name=$name src=$src url=$url</blink>";
	    if ($src)
	    {
	    	$framesrc = URI->new_abs( $src, $url );
		$linkHtml = &ICLinkHtml($framesrc,$name);
		print $linkHtml;
	    }
	}
    
}#end start_rtn
sub text_rtn {
# Execute when text is encountered
	$text = shift;
	if ($currentHREF && $linksOK)
	{
		if (isImageUrl($currentHREF))
		{
	    		$imageHtml = &ICImageHtml($currentHREF);
			print $imageHtml,"<br/>";
		}
		else
		{
			$linkHtml = &ICLinkHtml($currentHREF,$text);
			print $linkHtml;
		}
	}
}#text_rtn

sub isImageUrl
{
	my $url = shift;
	if (($url =~ /\.jpg$/i) || 
		($url =~ /\.png$/i) || 
		($url =~ /\.gif$/i) || 
		($url =~ /\.jpeg$/i) 
	)
	{	
		return 1;
	}
	else
	{
		return 0;
	}
}# isImageUrl
sub ICLinkHtml #($linkHREF, $linkText)
{
	($linkHREF,$linkText) = @_;

	#Make it come through our server for this URL
	$linkHREF = &ICLinkURL($linkHREF);
	
	return "<a href='" . $linkHREF . "'>" . $linkText . "</a><br/>\n"; 
}
sub end_rtn {
# Execute when the end tag is encountered
   
    	($tag, $hashref) = @_;
	#print "<B>GOT TAG " . $tag . "</B>";
	if ($tag eq "/a")
	{
		#print "<BLINK>GOT ONE</BLINK>";
		$currentHREF = "";
	}
}


sub HTML2TEXT       
{
    my $string  = shift;
    #print ("<B>HTML2TEXT $string <br></B>");

    $string =~ s/\</&lt;/g;
    $string =~ s/\>/&gt;/g;
    return $string;
}
sub HTTPEscapeString
{
    my $string  = shift;

    #print ("<B>HTTPEscapeString $string <br></B>");
    $string =~ s/\%/%25/g;
	$string =~ s/\"/%22/g;
    $string =~ s/\#/%23/g;
    $string =~ s/\$/%24/g;
    $string =~ s/\&/%26/g;
    $string =~ s/\+/%2B/g;
    $string =~ s/\//%2F/g;
    $string =~ s/\?/%3F/g;
    $string =~ s/\:/%3A/g;
    $string =~ s/\;/%3B/g;
    $string =~ s/\</%3C/g;
    $string =~ s/\=/%3D/g;
    $string =~ s/\>/%3E/g;
    $string =~ s/\@/%40/g;
    $string =~ s/ /\+/g;
    return $string;
}
sub HTTPUnEscapeString
{

    my $string  = shift;
    #print ("<B>HTTPUnEscapeString $string <br></B>");
	$string =~ s/%22/\"/g;
    $string =~ s/%23/\#/g;
    $string =~ s/%24/\$/g;
    $string =~ s/%25/\%/g;
    $string =~ s/%26/\&/g;
    $string =~ s/%2B/\+/g;
    $string =~ s/%2F/\//g;
    $string =~ s/%3F/\?/g;
    $string =~ s/%3A/\:/g;
    $string =~ s/%3B/\;/g;
    $string =~ s/%3C/\</g;
    $string =~ s/%3D/\=/g;
    $string =~ s/%3E/\>/g;
    $string =~ s/%40/\@/g;
    $string =~ s/\+/ /g;
    return $string;
}

sub hostname
{
	#return $ENV{"SERVER_NAME"} . ":" . $ENV{"SERVER_PORT"} ;
	#return "http://" . $ENV{"SERVER_ADDR"} . ":" . $ENV{"SERVER_PORT"} ;
	return $SERVER_URL;
}
sub ICLinkURL
{
	my $url = shift;
	my $script = $SCRAPER_SCRIPT;
	return &ICURL($url,$script);
}
sub ICImageURL
{
	my $url = shift;
	my $script = $IC_SCRIPT;
	return &ICURL($url,$script);
}
sub ICURL
{
	my $url = shift;
	my $script = shift;
	#print ("<B>ICURL $url <br> </B>");
	$ret = &hostname() . $script . "?url=" . &HTTPEscapeString($url) .
	"&minx=" . $minx . "&miny=" . $miny . "&x=" . $x . "&y=" . $y . "&jpgOK=on&keepRatio=on&submit=Go";
	if ($linksOK)
	{
		$ret .= "&linksOK=on";
	}	
	#print "<i>$ret</i><br/>";
	return $ret;
}

#gets HTML image tag for a converted image for any given URL.
#If the image occurs in the context of a link, that is also included.
sub ICImageHtml
{
	my $url = shift;
	my $icurl = &ICImageURL($url);
	my $imageHtml = "<img src=\"" . $icurl . "\" />";
	my $ret = "";
	#print ("<B>ICImageHtml for $url is $icurl <br> </B>");	
	#print ("<B>ICImageHtml currentHREF=$currentHREF<br> </B>");	
	if ($currentHREF)
	{
		$icpageurl = &ICPageUrl($currentHREF);
		$ret = "<a href=\"" . $icpageurl   . "\">" . $imageHtml . "</a>";
	}
	else
	{
		$ret = $imageHtml;
	}
	#print "<B>RET = $ret <br></B>";     
	return $ret;
}	

#given a url, create another URL that will force the client to access it 
#through this image conversion program.
sub ICPageUrl
{
	my $url = shift;
	#FIXME - DO NOT HARD CODE THIS !!!
	$iccgi = &hostname() . $SCRAPER_SCRIPT;             


	#http://127.0.0.1:8888/cgi-bin/html.pl?url=http%3A%2F%2Fwww.cnn.com&x=100&y=100&minx=30&miny=30&jpgOK=on
	$icpageurl = $iccgi . "?url=" . &HTTPEscapeString($url) . 
	"&x=" . $x . "&y=" . $y . "&minx=" . $minx . "&miny=" . $miny .
	"&jpgOK=on";
	if ($linksOK)
	{
		$icpageurl .= "&linksOK=on";
	}
	return $icpageurl;
}

sub printHtmlForm
{
	$url = "http://www.flickr.com/photos" unless $url;
	print "<form action=\"$SCRAPER_SCRIPT\" method=\"get\">URL:<input name=\"url\" value=\"" . $url . "\" /><br/>\n";
  	print "Max Width:<input name=\"x\" size=\"3\" value=\"" . $x . "\" /><br/>\n";
	print "Max Height:<input name=\"y\" size=\"3\" value=\"" . $y . "\" /><br />\n";
  	print "Min Width:<input name=\"minx\" size=\"3\" value=\"" . $minx . "\" /><br />\n";
	print "Min Height:<input name=\"miny\" size=\"3\" value=\"" . $miny . "\" /><br />\n";
	print "Accept PNG:<input type=\"checkbox\" name=\"pngOK\" /><br />\n";
	print "Accept JPG:<input type=\"checkbox\" name=\"jpgOK\" checked=\"true\" /><br />\n";
	print "Accept GIF:<input type=\"checkbox\" name=\"gifOK\" /><br />\n";
	print "Show hyperlinks:<input type=\"checkbox\" name=\"linksOK\" checked=\"true\" /><br />\n";
	print "Keep ratio:<input type=\"checkbox\" name=\"keepRatio\" checked=\"true\" /><br />\n";
	print "<input type=\"submit\" value=\"GO\"></form>\n";
}
sub printWmlForm
{
	print "URL:<input name=\"url\" value=\"http://www.google.com\" /><br/>\n";
  	print "Max Width:<input name=\"x\" size=\"3\" value=\"100\" /><br/>\n";
	print "Max Height:<input name=\"y\" size=\"3\" value=\"100\" /><br />\n";
  	print "Min Width:<input name=\"minx\" size=\"3\" value=\"30\" /><br />\n";
	print "Min Height:<input name=\"miny\" size=\"3\" value=\"30\" /><br />\n";
	#print "Accept PNG:<input type=\"checkbox\" name=\"pngOK\" /><br />\n";
	#print "Accept JPG:<input type=\"checkbox\" name=\"jpgOK\" checked=\"true\" /><br />\n";
	#print "Accept GIF:<input type=\"checkbox\" name=\"gifOK\" /><br />\n";
	#print "Keep ratio:<input type=\"checkbox\" name=\"keepRatio\" /><br />\n";
	print "<do type=\"accept\" label=\"OK\">";
	print "  <go href=\"$SCRAPER_SCRIPT\" method=\"get\">\n";
	print "    <postfield name=\"url\" value=\"$(url)\" />\n";
	print "    <postfield name=\"x\" value=\"$(x)\" />\n";
	print "    <postfield name=\"y\" value=\"$(y)\" />\n";
	print "    <postfield name=\"miny\" value=\"$(miny)\" />\n";
	print "    <postfield name=\"minx\" value=\"$(minx)\" />\n";
	print "  </go>\n";
	print "</do>";  
}
