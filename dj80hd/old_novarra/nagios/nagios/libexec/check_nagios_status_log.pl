#!/usr/local/groundwork/bin/perl -w
#
# $Id: check_nagios_status_log.pl,v 1.3 2005/03/03 23:03:25 hmann Exp $
#
# This script reads the nagios status log and returns the status of the 
# specified service and/or host list.
#
# Copyright 2007 GroundWork Open Source, Inc. (“GroundWork”)  
# All rights reserved. This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License version 2 as published 
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY 
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this 
# program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, 
# Fifth Floor, Boston, MA 02110-1301, USA.
#
# Changelog
#   Peter Loh - 2/2005 
#     Initial Revision
#   Harper Mann - 25-Feb-2005
#     Added list of hosts / services
#
use strict; 
use Getopt::Long;
use vars qw($rval @hostlist @servicelist $statlog $opt_l $opt_p $opt_H $opt_s $opt_V $opt_h $verbose $PROGNAME);
use lib "/usr/local/groundwork/nagios/libexec";
use utils qw(%ERRORS &print_revision &support &usage);

my $debug = 0;
my $StatusLog = "/usr/local/groundwork/var/status.log";

$PROGNAME="check_nagios_status_log";

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions
    ("H=s" => \$opt_H, "hosts=s" 	=> \$opt_H,
     "s=s" => \$opt_s, "services=s" => \$opt_s,
     "l"   => \$opt_l, "list"    	=> \$opt_l,
     "p"   => \$opt_p, "path"    	=> \$opt_p,
     "V"   => \$opt_V, "version"    => \$opt_V,
     "h"   => \$opt_h, "help"       => \$opt_h,
     "D"   => \$debug, "debug"      => \$debug);

if ($opt_h) { print_help(); exit $ERRORS{'OK'} }

if (!$opt_l && !$opt_s && !$opt_H) {
	print "** host or service required **\n\n"; 
	print_usage();
	exit $ERRORS{'UNKNOWN'};
}

if ($opt_s) { @servicelist = split(/,/, $opt_s) }
if ($opt_H) { @hostlist = split(/,/, $opt_H) }

if ($opt_V) {
    print_revision($PROGNAME,'$Id: check_nagios_status_log.pl,v 1.3 2005/03/03 23:03:25 hmann Exp $');
    exit $ERRORS{'OK'};
}

if ($opt_p) { $StatusLog = $opt_p }

my ($state,$host,$rtn,@parms,%service_status_codes,$service,$servicename,$line,$type,$logtime,$hostname,$tmp,$status);
my $worst = $ERRORS{'OK'};

open STATUSLOG, $StatusLog || 
	die "Can't open nagios status log $StatusLog: $!\n" ;

while (<STATUSLOG>) {
	chomp;
	$hostname = "";
	$servicename = "";
	$status = "";
	if (/\[(\d+)\]\sHOST;\s*(.*?);(.*?);(.*?);(.*?);(.*)/) {
		$logtime = $1;
		$hostname = $2;
		$tmp = $3;
		$status = $3;
		print "Found host $hostname:$tmp\n" if $debug;
	} elsif (/\[(\d+)\]\sSERVICE;\s*(.*?);\s*(.*?);(.*?);/) {
		$logtime = $1;
		$hostname = $2;
		$servicename = $3;
		$status = $4;
		print "Found service: $hostname:$servicename:$tmp\n" if $debug;
	}

	# -l switch just lists the availble Hosts and services without check
	if ($opt_l) {
		if ($servicename) {
			print "Service - $hostname : $servicename : $status\n";
		} else {
			print "Host - $hostname : $status\n";
		}
		next;
	}

	# Search hosts and services lists and each log file line
	if ($hostname) {
		# Service processing
		if ($servicename) {
			foreach (@servicelist) {
				my @vals;
				@vals = split(/\:/);
				$host = $vals[0];
				$service = $vals[1];
				$state = $vals[2];
				print "Looking for: $host:$service:$state\n" if $debug;

				if ($hostname =~ /^$host$/i && $servicename =~ /^$service$/i) {
					if ($status =~ /$state/i) {
						$rval .= "*$host:$service:$status ";
						$rtn = $ERRORS{$status};
						if ($rtn > $worst) { $worst = $rtn }
					}
				}
			}

		# Hosts processing
		} else {
			foreach (@hostlist) {
				my @vals;
				@vals = split(/\:/);
				$host = $vals[0];
				$state = $vals[1];
				print "Looking for: $host:$state\n" if $debug;

				if ($hostname =~ /^$host$/i) {
					if ($status =~ /$state/i) {
						$rval .= "*$hostname:$status ";
						if ($status eq "UNREACHABLE") { $status = "UNKNOWN" }
						if ($status eq "DOWN") { $status = "CRITICAL" }
						$rtn = $ERRORS{$status};
						if ($rtn > $worst) { $worst = $rtn }
					}
				}
			}
		}
	}
}
close STATUSLOG;

if ($rval) { print "PROBLEM: $rval\n" } 
else { print "All hosts and services are OK\n" }

exit $worst;

sub print_usage () {
    print "Usage:
   $PROGNAME -H <host:state,...> -s <host:service:state,...> [-l] [-v] [-h] [-V]
   $PROGNAME --help
   $PROGNAME --version
";
}

sub print_help () {
    print_revision($PROGNAME,'$Id: check_nagios_status_log.pl,v 1.3 2005/03/03 23:03:25 hmann Exp $');
    print "\n

Check list of hosts and services in Nagios status.log. If any are found to match the states specfied, output worst status matched and a list of hosts and services found in the specified states.

";
    print_usage();
    print "
Help:
-s, --hosts=<host:state,...>
   List of hosts to check. Comma separated list for multiple sets
   state=Down
-s, --services=<host:service:state,...>
   List of services to check. Comma separated list for multiple sets
   state=Warning,Critical 
-p, --path=<path/file>
   Path to Nagios status.log
-l, --list
   List all hosts and services found in Nagios status.log
-v, --verbose
   Print extra debugging information
-V, --version
   Show version and license information
-h, --help
   Show this help screen

Check_nagios_status_log checks a list service states so that application
checks can be clustered into one alarm.  If a host or service is in the 
specified non-OK state, this plugin returns the worst alarm state and a 
list of services in an alarm state.\n
";
}
