#!/usr/local/groundwork/bin/perl -wT
#
# $Id: rap_rise_rrd.pl,v 1.3 2005/09/28 19:20:36 djohnson Exp $
#

# Check Rapid rise in rrd with Nagios
#
# usage:
#    rap_rise_rrd rrdfile [ds] warning critical interval
#
#    interval in minutes
# Copyright Notice: GPL
#

require '/usr/local/groundwork/nagios/libexec/utils.pm';
#makes things work when run without install
use lib qw( ../perl-shared/blib/lib ../perl-shared/blib/arch );
# this is for after install
use lib qw( /usr/local/groundwork/lib/perl ../lib/perl /usr/local/groundwork/nagios/libexec );
use RRDs;
use strict;			# RRD:File and utils.pm don't like this

$ENV{'PATH'} = "/bin:/usr/bin";
$ENV{'ENV'} = "";

if (scalar @ARGV != 4 && scalar @ARGV != 5) {
	print STDERR join "' '", @ARGV, "\n";
	my $foo = 'check_rrd_data';
	exit;
}

# Default
# Guess which RRD file have to be opened
my $rrdfile = $ARGV[0] if (-r $ARGV[0]);		# First the parameter
#	print "\$rrdfile = $rrdfile\n";

my $ds = defined $ARGV[1]?$ARGV[1]:0;
#	print "\$ds = " . $ds . "\n";
$ds =~ s/\$//g;		# Sometimes Nagios gives 1$ as the last parameter

my $warn = defined $ARGV[2] ? $ARGV[2] : 0;
#	print "\$warn = " . $warn . "\n";

my $crit = defined $ARGV[3] ? $ARGV[3] : 0;
#	print "\$crit = " . $crit . "\n";

my $in_interval = defined $ARGV[4] ? $ARGV[4] : 0;
#       print "\$in_interval = " . $in_interval . "\n";

# convert to seconds
my $interval=$in_interval*60;

# Find out last update time
my ($last) = RRDs::last ($rrdfile);
# print "\$last: ","$last\n";

# Calculate the start time to use
my $starttime=$last-$interval;

# Fetch the data
my ($start,$step,$names,$data) = RRDs::fetch ($rrdfile,"AVERAGE","-s",$starttime,"-e",$last);

# Calculate the rise
my $rise=0;
my $risefactor=0;

# Bunch of debugging print statements....

#  print "Start:       ", scalar localtime($start), " ($start)\n";
#  print "Step size:   $step seconds\n";
#  print "End:   ", scalar localtime($last), " ($last)\n";
#  print "Interval $interval seconds\n";
#  print "DS names:    ", join (", ", @$names)."\n";
#  print "Data points: ", $#$data, "\n";
#  print "Data:\n";


  foreach my $line (@$data) {
    $start += $step;
    if ($start > $last) {
	last;
    }
#    print "  ", scalar localtime($start), " ($start) ";

    foreach my $val (@$line) {
        if ($val > $rise) {
           $rise=$val;
	   $risefactor++;
	}     
#	print  $val;
    }
#    print "\n";
  }

# Ok, got the value we wanted....
# First check for critical errors
if ($risefactor >= $crit) {
	print "RRD CRITICAL - Rapid Rise detected", $risefactor, "values out of last", $in_interval, "increasing\n";
	exit 2;		# Critical
}

# Check for warnings
if ($risefactor >= $warn) {
	print "RRD WARNING $risefactor values out of last $in_interval increasing\n";
	exit 1;		# Warning
}

# Normally returns 0 (OK)
print "RRD Check OK \n";
exit 0
