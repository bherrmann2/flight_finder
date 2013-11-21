#!/usr/local/groundwork/bin/perl -wT

#
# $Id: pat_match_rrd.pl,v 1.3 2005/09/28 19:20:36 djohnson Exp $
#
# Checks RRDs for pattern matching with Nagios 
#
# usage:
#    pat_match_rrd reference_rrdfile [ds] measurement_rrdfile [ds]  warning critical interval
#
#    interval in minutes is how for back to look for a similar value in the reference rrd
#    warn is the threshold for difference in reference and measurement (absolute value) needed for warning
#    crit is the threshold for difference in reference and measurement (absolute value) needed for critial
#
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

if (scalar @ARGV != 7 && scalar @ARGV != 5) {
	print STDERR join "' '", @ARGV, "\n";
	my $foo = 'check_rrd_data';
	exit;
}

# Default
# Get parameters into variables
my $ref_rrdfile = $ARGV[0] if (-r $ARGV[0]);		
my $ref_ds = defined $ARGV[1]?$ARGV[1]:0;
my $rrdfile = $ARGV[2] if (-r $ARGV[2]);           
my $ds = defined $ARGV[3]?$ARGV[3]:0;
my $warn = defined $ARGV[4] ? $ARGV[4] : 0;
my $crit = defined $ARGV[5] ? $ARGV[5] : 0;
my $in_interval = defined $ARGV[6] ? $ARGV[6] : 0;

# convert to seconds
my $interval=$in_interval*60;

# Find out last update time
my ($last) = RRDs::last ($rrdfile);
# print "\$last: ","$last\n";

# Calculate the start time to use in reference RRD
my $starttime=$last-$interval;

# Fetch the reference data
my ($start,$step,$names,$data) = RRDs::fetch ($ref_rrdfile,"AVERAGE","-s",$starttime,"-e",$starttime);

# Assign the reference value
my $i;
my $found_index;
for ($i= 0; $i < @$names; $i++) {
        if (@$names[$i] eq $ref_ds) {
            $found_index = $i;
            last;
        }
}
my $ref_value = @$data[0]->[$found_index];

# Fetch the current data
($start,$step,$names,$data) = RRDs::fetch ($rrdfile,"AVERAGE","-s",$last,"-e",$last);

# Assign the current value
for ($i= 0; $i < @$names; $i++) {
        if (@$names[$i] eq $ds) {
            $found_index = $i;
            last;
        }
}
my $value = @$data[0]->[$found_index];

# Now, calculate the difference

my $diff=abs($value-$ref_value);
# print"Diff = ", $diff,"\n";

# Ok, got the value we wanted....
# First check for critical errors
if ($diff >= $crit) {
	printf "RRD CRITICAL - Difference too big: Current: %.3f reference: %.3f \n", $value, $ref_value;
	exit 2;		# Critical
}

# Check for warnings
if ($diff >= $warn) {
	printf "RRD WARNING - Difference is big: Current: %.3f reference: %.3f \n", $value, $ref_value; 
	exit 1;		# Warning
}

# Normally returns 0 (OK)
print "RRD Reference Check OK \n";
exit 0
