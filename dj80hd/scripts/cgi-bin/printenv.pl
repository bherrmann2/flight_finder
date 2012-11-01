#!/usr/bin/perl -w
##
##  printenv -- demo CGI program which just prints its environment
##

print "Content-type: text/html\n\n";
print "<html><body>";
foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "${var}=\"${val}\"<br>\n";
}
print "</body></html>";

