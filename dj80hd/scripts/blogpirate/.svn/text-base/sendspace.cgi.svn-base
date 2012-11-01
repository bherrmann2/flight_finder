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
# 05-JAN-2010 Support now interface that requires post 
#
my $TEST_URL = "http://www.sendspace.com/file/70vebf";
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
  $link_enc = 'http://dj80hd.com' unless ($link_enc); #default;
  print ">>>LINK ENC $link_enc \n" unless (!$command_line_mode);
  my $redirect =  $q->redirect (-URL => $link_enc);
  print ">>>REDIRECT\n" unless (!$command_line_mode);
  print $redirect;
}
else {
  error ("<form>URL:<input name='url' value='" . $TEST_URL . "' size='45'><input type='submit' value='Go'></form>");
}
#<a id="downlink" class="mango" href="http://fs11n3.sendspace.com/dl/1ca61c2536f218a55628b49ea29a54ae/4abbaa5e0373dce5/70vebf/Slyde%20DJ%20mix.zip"   
  
#http://fs11n3.sendspace.com/dl/1ca61c2536f218a55628b49ea29a54ae/4abbaa5e0373dce5/70vebf/Slyde%20DJ%20mix.zip
sub get_downloadable_url {
  my $url = shift;
  my $b = LWP::UserAgent->new();
  my $cookie_jar = HTTP::Cookies->new;
  $b->cookie_jar($cookie_jar);
  my $resp = $b->post($url,['download' => '&nbsp;REGULAR DOWNLOAD&nbsp;']);
  print ">>>COOKIES:" . $cookie_jar->as_string() . "\n" unless (!$command_line_mode);
  my $content = $resp->content();
  if ($content =~ /<a id="downlink" class="mango" href="(\S+)"/) {
    my $second_url = $1;
    print ">>>SECOND URL: $second_url\n" unless (!$command_line_mode);
    return $second_url;
  }
  else {
    print ">>>FAILED MATCH CONTENT:\n" unless (!$command_line_mode);
    print $content unless (!$command_line_mode);
    return 'http://dj80hd.com';
  }
}#end sub

sub error {
  my $msg = shift;
  print "Content-Type: text/html\n\n";
  print $msg;
}

