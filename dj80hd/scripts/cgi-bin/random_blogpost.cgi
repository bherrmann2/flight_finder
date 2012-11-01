#!/usr/bin/perl

use strict;
use CGI;
use LWP::UserAgent;

# new CGI 
my $q = CGI->new( );
my $blogid = $q->param("blogid");
if ($blogid && !is_blog_id($blogid)) {
  $blogid = find_blog_id_for_blog_name($blogid);
}
if ($blogid && !is_blog_id($blogid)) {
  error_exit("Invalid blogid: $blogid");
}
if (!$blogid) {
  error_exit("No blogid (e.g. 3290837777254304862) was provided");
}

#$blogid = '3290837777254304862' unless $blogid;
my $url = 'http://www.blogger.com/feeds/' . $blogid . '/posts/default?max-results=500000';
my $resp = get_resp($url);
if ($resp->code != 200) {
  error_exit("HTTP " . $resp->code . " from url " . $url);
}
my $content = $resp->content;
my @hrefs = ();
while ($content =~ m/<link rel='alternate' type='text\/html' href='(http:\/\/\S+)'/gi) {push @hrefs,$1;}

if ($#hrefs >= 0) {
  my $index = int(rand($#hrefs));
  my $rdurl = $hrefs[$index];
  if ($rdurl =~ /^http/) {
    print $q->redirect( -URL => $rdurl);
  }
  else {
    error_exit("Invalid Redirect URL " . $rdurl);
  }
}
else {
  error_exit("Could not find any links in $url");
}

sub error_exit {
  my $msg = shift;
  print $q->header(); 
  print "ERROR: " . $msg;           
  exit;
}

#finds the id (e.g. 4648217031682098260 for a blog name (e.g. notmanyexperts)
sub find_blog_id_for_blog_name {
  my $name = shift;
  my $url = "http://" . $name . ".blogspot.com";
  my $resp = get_resp($url);
  if ($resp->content =~ /blogID=(\d+)/) {
    return $1;
  }
  return;
}

sub get_resp {
  my $url = shift;
  my $b = LWP::UserAgent->new();
  $b->cookie_jar({});
  return $b->get($url);
}

sub is_blog_id {
  my $id = shift;
  return ($id =~ /^\d+$/);
}
