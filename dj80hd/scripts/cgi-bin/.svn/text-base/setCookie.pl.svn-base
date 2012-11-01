#!/usr/bin/perl -w

use CGI;

$q = CGI::new();
$c = $q->param("c");

if ($c == "1")
{
print "Set-cookie: NovACA001=BLAM; SESSIONID=HOWDY; Max-Age=83772\n"; 
   
}
#PASSWORD_OK = NO
elsif ($c == "2")
{
print "Set-cookie: NovACA001=BLAM; PASSWORD_OK=\"NO\";\n"; 
 
}
#DISCLAIMER to no for 2 mintues
elsif ($c == "3")
{
print "Set-cookie: NovACA001=BLAM; DISCLAIMER=\"NO\"; max-age=120\n"; 
}
#exprire DISCLAIMER to no for 2 mintues
elsif ($c == "4")
{
print "Set-cookie: NovACA001=BLAM; DISCLAIMER=\"NO\"; max-age=0\n"; 
}

elsif ($c == "5")
{
print "Set-cookie: NovACA001=BLAM; PASSWORD_OK=YES;\n"; 
 
}
elsif ($c == "6")
{
print "Set-cookie: NovACA001=BLAM; Complete kjdfad8f8df Max-Ageldjfia;\n"; 
 
}
#expire session
elsif($c == "7")
{
print "Set-cookie: NovACA001=BLAM; SESSIONID=byebye; Max-Age=0\n"; 
}
elsif($c == "8")
{
print "Set-cookie: NovACA001=BLAM; SESSIONID=again; Max-Age=60\n"; 
}

else
{
    #
}

print "Content-Type: text/html\n\n"; # <-- two newlines
#$q->cookie(-name => $name, -value => $vaue, -expires => $exp);

print "NAME: $name<br> VALUE: $value<br>EXPRIES: $exp<br>";
exit;
