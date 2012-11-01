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

my $q = CGI->new();
my $code = "";
my $url = $q->param("url");
my $command_line_mode = 0;
if ($ARGV[0]) {
  $command_line_mode = 1;
  $url = $ARGV[0];           
  $url = "http://www.mediafire.com/?yjnizyimnzy" unless ($url =~ /^http/);
  print ">>>COMMAND LINE MODE url is $url\n";                          
}
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
  print ">>>CODE $code \n" unless (!$command_line_mode);
  my $link_enc = get_downloadable_url_for_code($code);
  print ">>>LINK ENC $line_enc \n" unless (!$command_line_mode);
  my $redirect =  $q->redirect (-URL => $link_enc);
  print ">>>REDIRECT\n" unless (!$command_line_mode);
  print $redirect;
}
else {
  error ("<form>URL:<input name='url' value='http://www.mediafire.com/?yjnizyimnzy' size='45'><input type='submit' value='Go'></form>");
}
  
  

sub get_downloadable_url_for_code {
  print ">>>In get_downloadable_url_for_code\n" unless (!$command_line_mode);
  my $code = shift;
  my $first_url = "http://www.mediafire.com/?" . $code;
  print ">>>FIRST URL $first_url\n" unless (!$command_line_mode);
  my $second_url = "";                                    
  my $b = LWP::UserAgent->new();
  my $cookie_jar = HTTP::Cookies->new;
  $b->cookie_jar($cookie_jar);
  my $resp = $b->get($first_url);
  print ">>>COOKIES:" . $cookie_jar->as_string() . "\n" unless (!$command_line_mode);
  my $content = $resp->content();
  #print ">>>FIRST CONTENT\n$content\n" unless (!$command_line_mode);
  # cu('yjnizyimnzy','32226cd833f1592705996eb03f624a5b6af6f33099e5caea4b4b09749f5888f1f4311a54ae6cb694f88835589f9fff66','zttbc'); 
  if ($content =~ /cu\('(\w+)','([a-zA-Z0-9]+)','(\S+)'\);/) {
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
    

# This was the if statement when the old example (above) was in operation:
#if ($content =~ /http:\/\/" \+ sServer \+'\/' \+(\S+) 'g\/' \+ sQk \+ '\/' \+ sFile/) {
#
#
#
#
#
#href=\"http://"+mL+'/' +vub9do+vlz3p1+v12dw9+vycywb+viydmc+v1w1y9+vutzbw+vcwcw3+vil59i+v3lkw3+vgcwcn+vtvuoh+vnsbg9+vlbgw5+vswgxw+vy1hsb+vdl39w+vhez53+vclwxa+vggey0+vbdvwp+vsg3np+vzoeyv+vdcbye+v3nug2+vsb3oh+vv1ynb+v2ushx+vyzdcb+vdveb5+vwiu1o+viiwwh+vszyy5+vya9t3+vsw02b+vyucy1+vycgwc+vblsi1+vybc1g+v2lgob+v39iwe+vwvxbc+vzpdsp+vccyak+va3w1b+vy9sc2+vuh1yw+v3wdgo+v9ohgc+vwyenw+vwy1wn+vsococ+vlhcb1+v92tbw+vn3ice+vdyane+v9w315+vsg9ly+vh5bow+vcgwpc+vpzb5b+vuh35c+v3wcsy+val5uy+vbwhub+veiwob+vgc2ww+vwlc3u+v1t3yh+vyohxp+vdhycm+vscvkc+vd51bh+v1ooyc+vkgce9+vo3jc9+vtso05+vjc2yh+vw2oyw+v9k11w+vwypwh+vibnvs+vwi0jw+vvyvwy+vw1hyl+v9wswy+vwhw21+vbmsbw+vz3mhh+v9wywl+v59bw0+vuway2+vvce5b+vvpwww+vbyg9z+vjjhs0+vbyhxu+v9cong+vbyghn+vkey2c+vy99sd+vdp3wz+vzyddc+'g/'+mH+'/'+mY+'"> Click here to start download..</a>';}else{parent.aa(0,"ERROR:


#Example Download URL: 
#http://download531.mediafire.com/nxygjfncnppg/yjnizyimnzy/01+What+You+Need+%28Extended+Mix%29.mp3
    if ($content =~ /http:\/\/"\+mL\+'\/' \+([^']+)'g\/'\+mH\+'\/'\+mY/) {
      #print "GOT IT:" . $1 . "!!!";
      my @x = split(/\+/,$1);
      #print join("\n",@x);
      my $url = "http://" . $v{'mL'} . "/";
      foreach (@x) {
        $url .= $v{$_};
      }
      $url .= "g/" . $code . "/" . $v{"mY"}; 
      return $url;
    }
    else {
      print ">>>FAILED MATCH 2 CONTENT:\n" unless (!$command_line_mode);
      print $content unless (!$command_line_mode);
      return;
    }
  }
  else {
    print ">>>FAILED MATCH 1\n" unless (!$command_line_mode);
    return;      
  }
}#end sub

sub error {
  my $msg = shift;
  print "Content-Type: text/html\n\n";
  print $msg;
}
