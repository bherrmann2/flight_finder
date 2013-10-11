#!/usr/bin/perl

##################################################################
#
# nov_check_port.pl
#
# By: Wes Hegge
# Date: 11-05-2008
#
# Check if port is listening on server 
#
# Do this by ssh'ing to the ACA and executing this command
#     netstat -anp | grep -e ":<port_number> "
#
# Usage: nov_check_port.pl -H <host_address> -p <port_address>
###################################################################

use strict;
use Getopt::Std;

my $VERSION = "0.1-Development";
use vars qw ($USAGE $VERSION $opt_h $opt_H $opt_V $opt_p);
use vars qw ($cmd @output);

###########################################################
# helpers for returning plugin results to nagios
###########################################################
sub nagios_unknown {
    my $errmsg = shift;
    print STDOUT "PORT ERROR UNKNOWN: ", $errmsg, "\n";
    exit 3;
}

sub nagios_critical {
    my $errmsg = shift;
    print STDOUT "PORT ERROR: ", $errmsg, "\n";
    exit 2;
}

sub nagios_ok {
    my $ok_msg = shift;
    print STDOUT "OK: ", $ok_msg, "\n";
    exit 0;
}

###########################################################
# USAGE
#  returns nagios ret codes:
#    0 OK
#    2 CRITICAL
#    3 UNKNOWN (internal error)
###########################################################
$USAGE = <<EOUSAGE;
Usage: nov_check_port.pl -H host -p port
      example: nov_check_port.pl -H 172.16.0.28 -p 80  
EOUSAGE

###########################################################
# parse cmd line
###########################################################
getopts('hH:p:u:w:c:V');
if ($opt_V) { print "$0 ${VERSION}\n"; exit 0; }
if ($opt_h) { print "${USAGE}\n";      exit 0; }
nagios_unknown "Missing host param\n$USAGE" unless $opt_H;
nagios_unknown "Missing port param\n$USAGE" unless $opt_p;

$cmd = "ssh nagios\@$opt_H 'netstat -anp | grep -e \":$opt_p \" | grep -e \" LISTEN \"'";

@output = `$cmd`;

my $number_ports_returned = @output;

nagios_critical "$opt_p in NOT listening\n" unless ( $number_ports_returned != 0 );
nagios_ok "$opt_p is listening\n";
