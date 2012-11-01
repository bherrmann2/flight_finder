#!/usr/bin/perl -w
##
##  printenv -- demo CGI program which just prints its environment
##

print "Content-type: text/vnd.wap.wml\n\n";

print "<?xml version=\"1.0\"?>\n";
print "<!DOCTYPE wml PUBLIC \"-//WAPFORUM//DTD WML 1.1//EN\" \"http://www.wapforum.org/DT/wml_1.1.xml\">\n";
print "<wml><card><p>";
foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    $val =~ s/>/&lt;/g;
    $val =~ s/</&gt;/g;
    print "${var}=\"${val}\"<br/>\n";
}
print "</p></card></wml>";
#OWG1UP/4.1.20a UP.Browser/4.1.20a-XXXX UP.Link/4.1.HTTP-DIRECT

