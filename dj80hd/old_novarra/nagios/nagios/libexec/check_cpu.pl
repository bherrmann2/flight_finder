#!/usr/local/groundwork/bin/perl -w
#
# $Id: check_cpu,v 1.7 2004/06/22 16:51:05 hmann Exp $
#
# check_cpu checks CPU and returns sar stats
#
# Copyright (c) 2000-2004 Harper Mann. All rights reserved
# (harper.mann@comcast.net)
#
# No warrenty of any kind is granted io implied.
#
# Change Log
#----------------
# 15-Feb-2004 - Harper Mann
#	Initial revision
# 19-Mar-2004 Harper Mann
#	Fixed to use /proc instead of sar
# 23-Mar-2004 Harper Mann
#	Back to sar so numbers match.  Beta release
# 4-Jun-2004 - Harper Mann
#	Changed idle value to be a < test
# 21-Jun-2004 - Harper Mann
#	Added switch for CPU
#
use strict;

my @sar_vals = undef;
my @lines = undef;
my @res = undef;

my $PROCSTAT = "/proc/stat";

my $cpu;
my $userwarn = 101;
my $usercrit = 101;
my $nicewarn = 101;
my $nicecrit = 101;
my $syswarn = 101;
my $syscrit = 101;
my $idlewarn = 0;
my $idlecrit = 0;

my $debug = 0;
my $perf = 0;

my $SAR = "/usr/local/groundwork/bin/sar"; 

use Getopt::Long;
use vars qw($opt_V $opt_c $opt_s $opt_n $opt_u $opt_i $opt_D $opt_p $opt_h);
use vars qw($PROGNAME);
use lib "/usr/local/groundwork/nagios/libexec"  ;
use utils qw($TIMEOUT %ERRORS &print_revision &support &usage);

sub print_help ();
sub print_usage ();

$PROGNAME = "check_cpu";

Getopt::Long::Configure('bundling');
my $status = GetOptions
       ( "V"   => \$opt_V, "Version"  => \$opt_V,
         "c=s" => \$opt_c, "cpu=s"   => \$opt_c,
         "u=s" => \$opt_u, "user=s"   => \$opt_u,
         "n=s" => \$opt_n, "nice=s"   => \$opt_n,
         "s=s" => \$opt_s, "system=s" => \$opt_s,
         "i=s" => \$opt_i, "idle=s"   => \$opt_i,
         "D"   => \$opt_D, "debug"    => \$opt_D,
         "p"   => \$opt_p, "performance" => \$opt_p,
         "h"   => \$opt_h, "help"     => \$opt_h );

if ($status == 0) { print_usage() ; exit $ERRORS{'UNKNOWN'}; }

# Debug switch
if ($opt_D) { $debug = 1 }

# Cpu switch
if ($opt_c) { $cpu = $opt_c } else { $cpu = 0 }
print "CPU: $cpu\n" if $debug;

# Performance switch
if ($opt_p) { $perf = 1; }

# Version
if ($opt_V) {
        print_revision($PROGNAME,'$Revision: 1.7 $');
        exit $ERRORS{'OK'};
}

if ($opt_h) {print_help(); exit $ERRORS{'UNKNOWN'}}

# Options checking
# Percent CPU system utilization
if ($opt_s) { 
	($syswarn, $syscrit) = split /:/, $opt_s;

	($syswarn && $syscrit) || usage ("missing value -s <warn:crit>\n");

	($syswarn =~ /^\d{1,3}$/ && $syswarn > 0 && $syswarn <= 100) &&
	($syscrit =~ /^\d{1,3}$/ && $syscrit > 0 && $syscrit <= 100) ||
		usage("Invalid value: -s <warn:crit> (system percent): $opt_s\n");

	($syscrit > $syswarn) || 
		usage("system critical (-s $opt_s <warn:crit>) must be > warning\n");
}

# Percent CPU nice utilization
if ($opt_n) {
	($nicewarn, $nicecrit) = split /:/, $opt_n;

	($nicewarn && $nicecrit) || usage ("missing value -n <warn:crit>\n");

	($nicewarn =~ /^\d{1,3}$/ && $nicewarn > 0 && $nicewarn <= 100) &&
	($nicecrit =~ /^\d{1,3}$/ && $nicecrit > 0 && $nicecrit <= 100) ||
		usage("Invalid value: -n <warn:crit> (nice percent): $opt_n\n");

	($nicecrit > $nicewarn) || 
		usage("nice critical (-n $opt_n <warn:crit>) must be > warning\n");
}

# Percent CPU user utilzation
if ($opt_u) {
	($userwarn, $usercrit) = split /:/, $opt_u;

	($userwarn && $usercrit) || usage ("missing value -u <warn:crit>\n");

	($userwarn =~ /^\d{1,3}$/ && $userwarn > 0 && $userwarn <= 100) &&
	($usercrit =~ /^\d{1,3}$/ && $usercrit > 0 && $usercrit <= 100) ||
		usage("Invalid value: -u <warn:crit> (user percent): $opt_u\n");

	($usercrit > $userwarn) || 
		usage("user critical (-u $opt_u <warn:crit>) must be < warning\n");
}

# Percent CPU idle utilzation
if ($opt_i) {
	($idlewarn, $idlecrit) = split /:/, $opt_i;

	($idlewarn && $idlecrit) || usage ("missing value -i <warn:crit>\n");

	($idlewarn =~ /^\d{1,3}$/ && $idlewarn > 0 && $idlewarn <= 100) &&
	($idlecrit =~ /^\d{1,3}$/ && $idlecrit > 0 && $idlecrit <= 100) ||
		usage("Invalid value: -i <warn:crit> (idle percent): $opt_i\n");

	($idlecrit < $idlewarn) || 
		usage("idle critical (-i $opt_i <warn:crit>) must be > warning\n");
}

# Read /proc/stat values.  The first "cpu " line has aggregate values if
# the system is SMP
#

my ($lbl, $user, $nice, $sys, $idle) = undef;
if ($cpu eq "ALL" ) {
	(@res = qx/$SAR 1/) || die "No output from sar: $!";
} else {
	(@res = qx/$SAR 1 -U $cpu/) || die "No output from sar: $!";
}
foreach (@res) {
	chomp;
	($lbl,$cpu,$user,$nice,$sys,$idle) = split(/\s+/);
	if (/average/) { last }
}

# Do the value checks
my $out = undef;
$out=$out."(cpu: $cpu) ";

$out=$out."user: $user";
($user > $usercrit) ? ($out=$out."(Critical) ") :
	($user > $userwarn) ? ($out=$out."(Warning) ") : ($out=$out."(OK) ");

$out=$out."nice: $nice";
($nice > $nicecrit) ? ($out=$out."(Critical) ") :
	($nice > $nicewarn) ? ($out=$out."(Warning) ") : ($out=$out."(OK) ");

$out=$out."sys: $sys";
($sys > $syscrit) ? ($out=$out."(Critical) ") :
	($sys > $syswarn) ? ($out=$out."(Warning) ") : ($out=$out."(OK) ");

$out=$out."idle: $idle";
($idle < $idlecrit) ? ($out=$out."(Critical) ") : 
	($idle < $idlewarn) ? ($out=$out."(Warning) ") : ($out=$out."(OK) ");

print "$out";

print " |cpu: $cpu user: $user nice: $nice sys: $sys idle: $idle\n" if $perf;

# Plugin output
# $worst == $ERRORS{'OK'} ?  print "CPU OK @goodlist" : print "@badlist";

# Performance? 

if ($out =~ /Critical/) { exit (2) }
if ($out =~ /Warning/) { exit (1) }
exit (0); #OK

# Usage sub
sub print_usage () {
        print "Usage: $PROGNAME 
	[-c, --cpu <cpu number>
	[-u, --user <warn:crit> percent
	[-n, --nice <warn:crit> percent
	[-s, --system <warn:crit> percent
	[-i, --idle <warn:crit> percent (NOTE: idle less than x)
	[-p] (output Nagios performance data)
	[-D] (debug) [-h] (help) [-V] (Version)\n";
}

# Help sub
sub print_help () {
        print_revision($PROGNAME,'$Revision: 1.7 $');

# Perl device CPU check plugin for Nagios

	print_usage();
	print "
-c, --cpu
   CPU Number (default is 0, ALL for all)
-u, --user
   Percent CPU user
-n, --nice
   Percent CPU nice
-s, --system=STRING
   Percent CPU system
-i, --idle
   If less than Percent CPU idle
-p, --performance
   Report Nagios performance data after the ouput string
-h, --help
   Print help
-V, --Version
   Print version of plugin
";

}

