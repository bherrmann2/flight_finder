#!/usr/local/groundwork/bin/perl --
# check_host_foundation.pl
# Nagios Plugin that checks the status of a host in GroundWork foundation. 
# 
#
# Requirements:
# GroundWork Foundation must be installed, and hosts status data must exist 
# 
#
# usage:
#    check_host_foundation -H $HOSTADDRESS$ 
#
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
# Changelog: 
# NOW - original version 
#
#
use strict;		
require 'utils.pm';
# Set up environment

$ENV{'PATH'} = "/bin:/usr/bin;/usr/local/groundwork/bin";
$ENV{'ENV'} = "";

# Initialize Variables
my @vals;
my @lines = undef;
my $debug = 0;
my $res = undef;
my $state = undef;
my $getparam;
my $nagiosdir = "/usr/local/groundwork/nagios/etc/\*";
my @field;

# Read the command line options

use Getopt::Long;
use vars qw($opt_H $opt_h $opt_V $opt_D);
use vars qw($PROGNAME);
use utils qw($TIMEOUT %ERRORS &print_revision &support &usage);
use CollageQuery ;

sub print_help ();
sub print_usage ();

$PROGNAME = "check_host_foundation";

Getopt::Long::Configure('bundling');
my $status = GetOptions
        ("V"   => \$opt_V, "Version"         => \$opt_V,
	"H=s"   => \$opt_H, "Host=s"         => \$opt_H,
      "D"   => \$opt_D, "debug"            => \$opt_D,
      "h"   => \$opt_h, "help"            => \$opt_h);

# Check if we can access Foundation (Collage)

my $t;
$t=CollageQuery->new() or die "Error: connect to CollageQuery failed!\n";

if ($opt_V) {
        print_revision($PROGNAME,'$Revision: 1.0 $'); #'
        exit $ERRORS{'OK'};
}

if ($opt_h) {print_help(); exit $ERRORS{'OK'};}

if (! $opt_H)
{
        print_usage() ;
        exit $ERRORS{'OK'};
}

if ($opt_D) {$debug = 1;}

# Find the hostname in the nagiosconifg
$getparam = `grep -b4 -a2 $opt_H $nagiosdir |grep host_name`;
@field = split /\s+/,$getparam;
$getparam=$field[2];
# Query Foundation
my %hash = $t->getHostStatusForHost($getparam);
foreach my $key (sort keys %hash) {
# Find the Host Status
	if ($key =~ /MonitorStatus/) {
		$state=$hash{$key};
		print "Host Status for host $getparam: $state\n";
	}
	print "$key=$hash{$key}\n" if $debug;
}
# Sort out the exit condition and status text

if (! $state) {
	print "Host Status for host $getparam: Not in Foundation\n";
	$res = 3;
	} else {
		if ($state =~ /UP/) {
			$res = 0;
		} else {
			if ($state =~ /DOWN/) {
				$res = 1;
			} else {
	        		if ($state =~ /UNREACHABLE/) {
        				$res = 2;
        			} else {
					if ($state =~ /PENDING/) {
                        			$res = 3;
                       		}
			} 
		} 
	}
}


exit ($res);


 
# Usage sub
sub print_usage () {
        print "Usage: $PROGNAME -H hostname
	[-h] (help) [-V] (Version) [-D] Debug\n";
}


# Help sub
sub print_help () {
        print_revision($PROGNAME,'$Revision: 1.0 $');
        print "Copyright (c) 2005 Thomas Stocking


";
        print_usage();
        print "
. The required arguments for this plugin are hostname only. You can and should use \$HOSTNAME\$ from Nagios. The plugin will return the current host state as recorded in the GroundWork Foundation database, which has to be installed. It also requires the CollageQuery.pm module, supplied with GroundWork Monitor. 
-H hostname
   Query Foundation for status of host 'hostname'
-h, --help
   Print help
-V, --Version
   Print version of plugin
-D, --Debug
   Turn on debug messages
";
}


