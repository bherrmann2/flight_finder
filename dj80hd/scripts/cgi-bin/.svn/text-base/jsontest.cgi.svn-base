#!/usr/bin/perl

use CGI;
use LWP::UserAgent;


# new CGI 
#my $q = CGI->new( );
#my $error;
#my $blogid = $q->param("blogid");
##$blogid = '3290837777254304862' unless $blogid;
#my $url = 'http://www.blogger.com/feeds/' . $blogid . '/posts/default?max-results=500000';

#my $b = LWP::UserAgent->new();
#$b->cookie_jar({});
#my $resp = $b->get($url);
#if ($resp->code != 200) {
#  $error = "HTTP " . $resp->code . " from url " . $url;
#}
#elsif (!$blogid) {
#  $error = "No blogid (e.g. 3290837777254304862) was provided)";
#}
#else {
#  my $content = $resp->content;
#  my @hrefs = ();
#  while ($content =~ m/<link rel='alternate' type='text\/html' href='(http:\/\/\S+)'/gi) {push @hrefs,$1;}
#  if ($#hrefs >= 0) {
#    my $index = int(rand($#hrefs));
#    my $rdurl = $hrefs[$index];
#    if ($rdurl =~ /^http/) {
#      print $q->redirect( -URL => $rdurl);
#    }
#    else {
#      $error = "Invalid Redirect URL " . $rdurl;
#    }
#  }
#  else {
#    $error = "Could not find any links in $url";
#  }
#}
#if ($error) {
#  print $q->header(); 
#  print $error;           
#}
$content = "{\"foo\": \"bar\"}";
$cl = length($content);
print "Content-Length: " . $cl . "\nContent-Type: application/json\n\n" . $content;
#print "Content-Type: text/html\n\n<b>Hi there</b>";
