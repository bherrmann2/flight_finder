#!/usr/bin/perl
#!perl
require LWP::UserAgent;
require HTTP::Cookies;
use CGI;
#!perl -w
# This program takes a mediafire URL as input and redirects the user to the
# actual downloadable mp3.
#
# Handles these formats for input url:
#
# http://www.mediafire.com/?yjnizyimnzy
# http://www.mediafire.com/download.php?14jwquwtt3y
# http://www.mediafire.com/file/yjnizyimnzy/01%20What%20You%20Need%20%28Extended%20Mix%29.mp3
# yjnizyimnzy
#
# 27-MAY-2009 Initial version based on zshare.cgi
# 29-MAY-2009 Support links ~ http://www.mediafire.com/download.php?14jwquwtt3y
#
my $TEST_URL = "http://www17.zippyshare.com/v/47078470/file.html";
my $q = CGI->new();
my $url = $q->param("url");
my $command_line_mode = 0;
if ($ARGV[0]) {
  $command_line_mode = 1;
  $url = $ARGV[0];           
  $url = $TEST_URL unless ($url =~ /^http/);
  print ">>>COMMAND LINE MODE url is $url\n";                          
}
if ($url) {
#$url = 'http://www.mediafire.com/?yjnizyimnzy' unless ($url);
  my $link_enc = get_downloadable_url($url);
  print ">>>LINK ENC $line_enc \n" unless (!$command_line_mode);
  my $redirect =  $q->redirect (-URL => $link_enc);
  print ">>>REDIRECT\n" unless (!$command_line_mode);
  print $redirect;
}
else {
  error ("<form>URL:<input name='url' value='" . $TEST_URL . "' size='45'><input type='submit' value='Go'></form>");
}

#http://www17.zippyshare.com/d/47078470ke/1253834845/47078470.mp3
#from
#var wannaplayagameofpong = 'fckhttp%3A%2F%2Fxxx17.zippyshare.com%2Fd%2F47078470oj%2F1253834848%2F47078470.mp3';
#
#
sub get_downloadable_url {
  my $url = shift;
  my $b = LWP::UserAgent->new();
  $b->header('Referer', $url);
  
  my $cookie_jar = HTTP::Cookies->new;
  $b->cookie_jar($cookie_jar);
  my $resp = $b->get($url);
  print ">>>COOKIES:" . $cookie_jar->as_string() . "\n" unless (!$command_line_mode);
  my $content = $resp->content();
  if ($content =~ /'\S+http%3A%2F%2Fxxx(\S+\.mp3)'/) {
    my $part = $1;
    $part =~ s/%2F/\//g;
    my $second_url = "http://www" . $part;
    print ">>>SECOND URL: $second_url\n" unless (!$command_line_mode);
    return $second_url;
  }
  else {
    print ">>>FAILED MATCH CONTENT:\n" unless (!$command_line_mode);
    print $content unless (!$command_line_mode);
    return;
  }
}#end sub

sub error {
  my $msg = shift;
  print "Content-Type: text/html\n\n";
  print $msg;
}
