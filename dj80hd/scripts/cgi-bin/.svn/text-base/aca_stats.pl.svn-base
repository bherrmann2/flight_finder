#!/usr/bin/perl
#!perl -w
require LWP::UserAgent;
use CGI;
$DEBUG = 0;

$NOVARRA_HOST_LIST = "v75.novarra.net,";

$q = new CGI;
print "Content-Type: text/html\n\n";
$form = "";


$list = $q->param("list");
@hosts = split(",",$list);

$action = $q->param("action");

&printForm;

if ($action eq "Get Stats")
{
 &printTable;
}
exit;


#-------------------------------------------------------------------------------

sub printForm
{
   print "Comma-seperated list of aca hostnames:<br>";
   print "<form method=post><input length=40 name=list value=\"" . $NOVARRA_HOST_LIST . "\"><input type=submit name=action value=\"Get Stats\"></form>\n";
}

sub getSessions #($host)
{
  my $host = shift;
  my $url = "http://" . $host . ":2666/SESSIONS";
  my $content = getUrlContent($url);
  $content =~ /Sessions \(used\/max\): (\d+)\//;
  return $1;
}#getSessions

sub getLatency
{
  my $host = shift;
  my $url = "http://" . $host . ":2666/STATS50";
  my $content = getUrlContent($url);
  #TD>STAT026<TD>0523202846<TD>0523203229<TD>2<TD>
  $content =~ /TD>STAT026<TD>\d+<TD>\d+<TD>(\d+)<TD>/;
  return $1;
}#getLatency  

sub printTable
{
  print "<hr><table border>\n";
  print "<tr><th>ACA</th><th>Sessions</th><th>Latency</th></tr>\n";
  foreach $host (@hosts)
  {
     print "<tr><td>" . $host . "</td><td>" . getSessions($host) . "</td><td>" . getLatency($host) . "</td></tr>\n"; 
  }
  print "</table>";
  
}


sub getUrlContent
{
  my $u = shift;
  my $ua = LWP::UserAgent->new(env_proxy => 1,
                              keep_alive => 1,
                              timeout => 20,
                             );
  $ua->agent('Mozilla/5.0');
  $request = HTTP::Request->new('GET', $u);

  $response = $ua->request($request); # or
  return $response->content;
}#getUrlContent

sub debug
{
my $s = shift;
print "$s<br>\n" unless (!$DEBUG);
}
sub cleanString
{
my $s = shift;
$s =~ s/^\s+//;
$s =~ s/\s+$//;
return $s;
}
