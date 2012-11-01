#!/usr/bin/perl
#!perl

use CGI;
use URI;

$PORN_DOMAINS_FILENAME = 'porndomains.txt';

$q = new CGI;

$url = $q->param("url");
print $q->header;

if ($url) {
  my $url = make_safe($url);
  my $host = get_host($url);
  my $cmd = "grep -i '$host' $PORN_DOMAINS_FILENAME";
  my $out = get_command_output($cmd);
  if ($out =~ /\w+/) {
    print "$host is <font color=red>PORN</font>!\n";
    print "<pre>" . $out . "</pre>";
  }
  else {
    print "$host is <font color=green>SAFE</font>!\n";
  }
}

print "<form>url:<input name=\"url\"/><input type=\"submit\" value=\"Go\"/></form>";


#Make it safe -
sub make_safe {
  my $url = shift;
  $url =~ s/<//g;
  $url =~ s/;//g;
  $url =~ s/<//g;
  $url =~ s/\|//g;
  $url =~ s/\s+//g;
  $url = "http://" . $url unless ($url =~ /^http/);
  return $url;
}

# NOTE: MAKE SURE THE COMMAND IS SAFE TO RUN before passing here
sub get_command_output {
  my $cmd = shift;
  open (C, "$cmd |");
  @lines = (<C>);
  close C;
  return join('',@lines);
}

sub get_host {
  my $url = shift;
  my $uri = URI->new($url);
  my $host = $uri->host;
  my @parts = split(/\./,$host);
  if ($#parts >= 1) {
    my $last_part = $parts[$#parts];
    my $second_last_part = $parts[$#parts - 1];
    my $last_two_parts = $second_last_part . "." . $last_part;
    if (($last_part eq "uk") && ($second_last_part eq "co") && $#parts >= 2) {
      return $parts[$#parts -2] . "." . $last_two_parts; #e.g. bbc.co.uk
    }
    else {
      return $last_two_parts; #e.g. dj80hd.com
    }
  }
  else {
    return $host;
  }
}
