#!/usr/local/groundwork/bin/perl -w
#
# $Id$
#
# Check_dell_hw calls omreport (Open Manage must be installed) to get status
# of Dell hardware
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
# Change Log
# 24-Jun-2004 Harper Mann
#   Initial Revision
#
use strict;

use Getopt::Long;

use vars qw($opt_V $opt_D $opt_h $opt_i);
use vars qw($PROGNAME);
use lib "/usr/local/groundwork/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support &usage);

sub print_help ();
sub print_usage ();

my ($return,$worst,$debug,$sev,$comp,$info) = 0;
my $cmd = "/usr/bin/omreport";
my $info_cmd = "$cmd system summary";
my $system_cmd = "$cmd system";
my $chassis_cmd = "$cmd chassis";
my (@ilines,@slines,@clines) = ();

$PROGNAME = "check_dell_hw";

# Initialize
$return = $ERRORS{'OK'};
$worst = $ERRORS{'OK'};

# Get the args
Getopt::Long::Configure('bundling');
my $status = GetOptions
	("V"  => \$opt_V, "version"  => \$opt_V,
	 "i"  => \$opt_i, "info"    => \$opt_i,
	 "h"  => \$opt_h, "help"    => \$opt_h,
	 "D"  => \$opt_D, "debug"    => \$opt_D);

# Bad Options get
if ($status == 0) {
	print_usage();
	exit $ERRORS{'OK'};
}

# Debug Flag
if ($opt_D) { $debug = 1 }

# Info Flag
if ($opt_i) { $info = 1 }

# Version print
if ($opt_V) {
	print_revision($PROGNAME,'$Revision$'); #'
	exit $return;
}

# HELP!
if ($opt_h) {print_help(); exit $return;}

# check if we can get to omreport and it's executable
if ( ! -x $cmd ) {
	print "$cmd not found or not executable.  Plug-in requires Dell Open Manage\n";
	exit $ERRORS{'UNKNOWN'} 
}

# Run commands and get output
@ilines = qx/$info_cmd/ if $info;
print @ilines if $debug;

@slines = qx/$system_cmd/;
print @slines if $debug;

@clines = qx/$chassis_cmd/;
print @clines if $debug;

# info output if requested
if ($info) {
	foreach (@ilines) {
		chomp;
		($sev,$comp) = split / : /;
		if ($sev) {
			if ($comp) { $comp =~ s/\s?$|\s+$/ / };
			if ($sev =~ /Chassis Model/) { print $comp }
			if ($sev =~ /Processor Family/) { print $comp }
			if ($sev =~ /Current Speed/) { print $comp }
			if ($sev =~ /Total Installed Capacity/) { print $comp }
			if ($sev =~ /IP Address/) { $comp =~ s/\[No Value\]//; print $comp }
		}
	}
}

# Chop the output and check for errors
foreach (@slines) {
	chomp;
	next if !/:/;
	next if /SEVERITY/;
	$worst = $ERRORS{'UNKNOWN'} if !/OK/i;
	$worst = $ERRORS{'WARNING'} if /WARNING/i;
	$worst = $ERRORS{'CRITICAL'} if /CRITICAL/i;
	($sev,$comp) = split / : /;
	$sev =~ s/\s+$//;
	print "$comp($sev) ";
	$return = $worst if $worst > $return; 
}

foreach (@clines) {
	chomp;
	next if !/:/;
	next if /SEVERITY/;
	$worst = $ERRORS{'UNKNOWN'} if !/OK/i;
	$worst = $ERRORS{'WARNING'} if /WARNING/i;
	$worst = $ERRORS{'CRITICAL'} if /CRITICAL/i;
	($sev,$comp) = split / : /;
	$sev =~ s/\s+$//;
	print "$comp($sev) ";
	$return = $worst if $worst > $return; 
}

# Final CR for CLI, everything after it ignored by Nagios
print "\n";

# Bye Bye!
exit ($return);

# Usage sub
sub print_usage () {
	print "Usage: $PROGNAME
	[-D] (Debug output)
	[-h] (Print help)
	[-V] (Version)\n";
}

# Help sub
sub print_help () {
        print_revision($PROGNAME,'$Revision$');
        print "Copyright (c) 2004 Groundwork Open Source Solutions, Inc., All Rights Reserved

Perl Dell hardware check for Nagios.  Uses omreport from Open Manage

";
        print_usage();
        print "
-D, --debug
   Print debug output
-h, --help
   Print help
-V, --version
   Print version information

";
}
