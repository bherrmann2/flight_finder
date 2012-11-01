#!/usr/bin/perl
#!perl
require LWP::UserAgent;
use CGI;
#!perl -w
# This program takes a URL as input, searches for all the zshare 
# hyperlinks on the page
# and downloads them all to a directory
#
#
# 26-FEB-2009 Updated regex to do multiline.
#

my $q = CGI->new();
$url = $q->param("url");
if ($url) {
  #Switch any audio zshare links to download.
  $url =~ s/\/audio\//\/download\//;
  
  #Get the content 
  my $ua = LWP::UserAgent->new;
  $ua->agent("MyApp/0.1 ");

  # Create a request (zshare expects a post to the url with download=1 data
  my $req = HTTP::Request->new(POST => $url);
  $req->content_type('application/x-www-form-urlencoded');
  $req->content('download=1');

  # Pass request to the user agent and get a response back
  my $res = $ua->request($req);

  my $content ="";
  # Check the outcome of the response
  if ($res->is_success) {
    $content = $res->content;
  }
  #
  # The line we are looking for looks like this:
  # var link_enc=new Array('h','t','t','p',':','/','/','6','9','.','8','0','.','2',' 5','4','.','1','7','9','/','d','o','w','n','l','o','a','d','/','4','2','0','a',' 4','7','6','2','c','c','f','7','e','f','2','f','7','c','1','0','9','2','e','3',' f','1','d','8','f','7','e','7','/','1','2','1','3','0','3','5','8','6','4','/',' 1','3','2','2','4','2','8','3','/','c','e','p','i','-','%','2','0','c','o','c',' o','t','t','e','%','2','0','i','n','%','2','0','m','y','%','2','0','h','e','a',' d','.','m','p','3');link = '';for(i=0;i<link_enc.length;i++){link+=link_enc[i];}
  # 
  if ($content =~ /var link_enc=new Array\((\S+)\)/m) {
    my $downloadable_url = "";             
    my $link_enc = $1;
    $link_enc =~ s/,//g;
    $link_enc =~ s/'//g;
    print $q->redirect (-URL => $link_enc);
  }
  else {
    error("Could not find downloadable link");
  }
}
else {
  error ("<form>URL:<input name='url' value='http://www.zshare.net/audio/56113593572e43d8/' size='45'><input type='submit' value='Go'></form>");
}

sub error {
  my $msg = shift;
  print "Content-Type: text/html\n\n";
  print $msg;
}
