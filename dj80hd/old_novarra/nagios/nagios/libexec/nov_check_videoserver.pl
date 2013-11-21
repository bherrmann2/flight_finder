#!/usr/bin/perl -w

use strict;
#use diagnostics;
# how does this differ from perl -w ?
#use warnings;
 
use LWP::UserAgent;
use Getopt::Std;
use Time::Local;
use POSIX qw(strtod);

use Getopt::Std;

use vars qw ($USAGE $VERSION $BASENAME);
use vars qw ($opt_V $opt_h $opt_H $opt_w $opt_c $opt_o);
use vars qw ($warn_thresh $crit_thresh);
use subs qw (getnum basename2 nagios_unknown nagios_critical nagios_warning nagios_ok);

$VERSION="0.1 17-Mar-2008";
$BASENAME=basename2($0);

$USAGE = <<EOUSAGE;
Usage: check_video_server -H host -oN

  where
    -H host gives host ip or name of the video server running healthcheckserver
    -o N gives the host resource to check and is defined as:
            1: last video server healthcheck code recorded.

  example:
      nov_check_video_server -H 172.22.0.66 -o1

  returns:
      nagios-formatted string. 

EOUSAGE

my ($nag_status, $perf_data);

#FIXME - Make a superclass or mixin with all this stuff shared accross nagios checks.
sub getnum {
    use POSIX qw(strtod);
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $! = 0;
    my($num, $unparsed) = strtod($str);
    if (($str eq '') || ($unparsed != 0) || $!) {
        return;
    } else {
        return $num;
    }
}

sub basename2 {
    my $fullname = shift;
    return ( $fullname =~ m{^.*\/([^/]+)}xms ? $1 : $fullname );
}
sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}


###########################################################
# helpers for returning plugin results to nagios
###########################################################
sub nagios_unknown {
    my ($subfun, $errmsg) = @_;
    print STDOUT "$subfun UNKNOWN - ", $errmsg, "\n";
    exit 3;
}

sub nagios_critical {
    my ($subfun, $errmsg, $perfdata) = @_;
    print STDOUT "$subfun CRITICAL - ", $errmsg, "| ", $perfdata, "\n";
    exit 2;
}

sub nagios_warning {
    my ($subfun, $errmsg, $perfdata) = @_;
    print STDOUT "$subfun WARNING - ", $errmsg, "| ", $perfdata, "\n";
    exit 1;
}

sub nagios_ok {
    my ($subfun, $ok_msg, $perfdata) = @_;
    print STDOUT "$subfun OK - ", $ok_msg, "| ", $perfdata, "\n";
    exit 0;
}

###########################################################
# execute remote cmd via ssh
###########################################################
sub check_via_nagios_ssh {
    my ($remote_cmd, $hostname) = @_;
    $hostname = "nagios\@$hostname";
    my $ssh_cmd = qq{ ssh -n -x -T $hostname "${remote_cmd}" };
    my $str=`${ssh_cmd}`;
    return $str;
}

###########################################################
# check the last know returncode of the healthcheck on the video server 
#  @param $hostname
#  @exit with single-line string of results to STDOUT, e.g.:
#    EXAMPLE GOES HERE
#  Standard format is at
#    http://nagiosplug.sourceforge.net/developer-guidelines.html#PLUGOUTPUT
#
#  Notes:
#  On the video server the healthcheck is issued via http from the load
#  balancer to the video server.
#  The results of this check are logged in the file
#  /home/novarra/tools/healthcheckserver/healthcheckserver.log
#
#  and the lines in this file have the following format:
#
#  Wed Mar 19 14:00:43 2008: 554 - [Errno 2] No such file or directory: 'type1.out'
#  Wed Mar 19 14:02:11 2008: 569 - Failed to get a SDP description from URL "rtsp://127.0.0.1/video/nocache/aHR0cDovL3NjaXNzb3Jzb2Z0LmNvbS90ZXN0L3NhdmUuZmx2.3gp": cannot handle DESCRIBE response: RTSP/1.0 404 Not Found
#
###########################################################
sub check_last_healthcheck_return_code {
    my $hostname = shift;
    my $output = check_via_nagios_ssh( "tail -n 10 /home/novarra/tools/healthcheckserver/healthcheckserver.log", $hostname );
    my @lines = reverse(split ("\n", $output)); #Most recent log lines are last, read them first.
   
    #Logic for reporting
    #If there are less than 2 samples, report the status as unknown.
    #Otherwise if both samples are in error report critical, if both are 200 report ok, if we have one of each give a warning.  
    my @samples = ();
    my $line = "";
    foreach $line (@lines) {
        if ($line =~ /(\w+ \w+ \d+ \d+:\d+:\d+ \d+): (\d+ - .+)/) {
	  push @samples, $2 . " (" . $1 . ")";
        }
    }
    if ($#samples < 1) {
       nagios_unknown "check_video_server", "Too Few Samples: " . ($#samples + 1) ;
    }
    elsif (($samples[0] =~ /^200 -/) && ($samples[1] =~ /^200 -/)) {
    	nagios_ok( "check_video_server", "host [$hostname]: OK " , trim($samples[0]) . ", " . trim ($samples[1]));
    }
    elsif (($samples[0] =~ /^200 -/) || ($samples[1] =~ /^200 -/)) {
    	nagios_warning( "check_video_server", "host [$hostname]: SUSPECT " , trim($samples[0]) . ", " . trim ($samples[1]));
    }
    else
    {
    	nagios_critical( "check_video_server", "host [$hostname]: CRITICAL " , trim($samples[0]) . ", " . trim ($samples[1]));
    }
}

###########################################################
# parse cmd line
###########################################################
getopts('VhH:o:');
if ($opt_V) { print "${BASENAME} ${VERSION}\n"; exit 0; }
if ($opt_h) { print "${USAGE}\n";      exit 0; }
nagios_unknown "check_video_server","Missing host param\n$USAGE" unless $opt_H;
nagios_unknown "nov_check_video_server",                      "Missing -o option\n$USAGE" unless $opt_o;

if ("1" eq $opt_o) {
  check_last_healthcheck_return_code($opt_H);
}
nagios_unknown "Unknown -o option [$opt_o]\n$USAGE" ;
