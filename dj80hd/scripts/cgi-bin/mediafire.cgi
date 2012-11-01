#!/usr/bin/perl
#!perl
require LWP::UserAgent;
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

my $q = CGI->new();
my $code = "";
my $url = $q->param("url");
#$url = 'http://www.mediafire.com/?yjnizyimnzy' unless ($url);

if ($url) {
  if ($url =~ /^http:\/\/www\.mediafire.com\/\?(\S+)$/) {
    $code = $1;
  }
  elsif ($url =~ /^http:\/\/www\.mediafire.com\/download\.php\?(\S+)$/) {
    $code = $1;
  }
  elsif ($url =~ /^http:\/\/www\.mediafire.com\/file\/(\w+)\//) {
    $code = $1;
  }
  else {
    $code = $url;
  }
  my $link_enc = get_downloadable_url_for_code($code);
  print $q->redirect (-URL => $link_enc);
}
else {
  error ("<form>URL:<input name='url' value='http://www.mediafire.com/?yjnizyimnzy' size='45'><input type='submit' value='Go'></form>");
}
  
  

sub get_downloadable_url_for_code {
  my $code = shift;
  my $first_url = "http://www.mediafire.com/?" . $code;
  my $second_url = "";                                    
  my $b = LWP::UserAgent->new();
  $b->cookie_jar({});
  my $resp = $b->get($first_url);
  my $content = $resp->content();
  # cu('yjnizyimnzy','32226cd833f1592705996eb03f624a5b6af6f33099e5caea4b4b09749f5888f1f4311a54ae6cb694f88835589f9fff66','zttbc'); 
  if ($content =~ /cu\('(\w+)','([a-zA-Z0-9]+)','(\S+)'\);/) {
  #if ($content =~ /cu\('(\w+)',([a-zA-Z0-0]+)'/) {
    $second_url = "http://www.mediafire.com/dynamic/download.php?qk=" . $1 . "&pk=" . $2 . "&r=" . $3;
    $resp = $b->get($second_url);
    $content = $resp->content;
    while ($content =~ m/var\s+(\S+)\s*=\s*'(\S+)'\s*;/gi) {
      $v{$1} = $2; 
    }
    #print %v;
  #parent.document.getElementById('download
  #_link').innerHTML = "<a onclick=\"document.getElementById('download_link').inner
  #HTML = 'Your download is starting.. ';\" href=\"http://" + sServer +'/' +vtnd5w+
  #vy39nl+vtwuxn+vz593d+vi3gzg+vawyts+v9wv5x+v1kwny+ve1hgy+vnsu3y+vvte9u+v9piiy+vlp
  #zts+vzwhn1+vas9d1+vbd3wt+vvyuwl+v1hp1e+vlayww+vgteic+ve1yw1+vz1e5l+vwxiii+vyl3cb
  #+vsjtgs+v9ytwx+vwjeeb+vysxgy+v5kjck+vnw9dl+vygebd+vww1wg+vzlhld+v1bi95+vgjhbb+vw
  #tzuy+vzahbw+v153yt+vygh5k+vupblz+vjxy1w+vwcywp+vg9sl3+viuehn+vihbeg+vectgh+vbecw
  #1+v1y5ut+viwzst+vv1iau+vylw5i+vcv5lh+v9wt9a+vi5wt5+v35wgu+vzuye9+vyuyih+vawtzn+v
  #1tde5+viiywb+v9zwpe+vllyig+vesywe+vwjewn+vhwl9u+vbbzwz+vt5thy+v1j15b+vc1clb+vltl
  #n9+ 'g/' + sQk + '/' + sFile + '"> Click here to start download..</a>';
#
    if ($content =~ /http:\/\/" \+ sServer \+'\/' \+(\S+) 'g\/' \+ sQk \+ '\/' \+ sFile/) {
      #print "GOT IT:" . $1 . "!!!";
      my @x = split(/\+/,$1);
      #print join("\n",@x);
      my $url = "http://" . $v{'sServer'} . "/";
      foreach (@x) {
        $url .= $v{$_};
      }
      $url .= "g/" . $ARGV[0] . "/" . $v{"sFile"}; 
      return $url;
    }
    else {
      return;
    }
  }
  else {
    return;      
  }
}#end sub

sub error {
  my $msg = shift;
  print "Content-Type: text/html\n\n";
  print $msg;
}
