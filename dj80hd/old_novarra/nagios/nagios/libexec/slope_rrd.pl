#!/usr/local/groundwork/bin/perl -wT

#
# $Id: slope_rrd.pl,v 1.3 2005/09/28 19:20:36 djohnson Exp $
#
# Checks RRDs for pattern matching with Nagios 
#
# usage:
#    slope_rrd.pl rrdfile [ds]  warning critical interval
#
#    warn is the threshold for warning on line slope
#    crit is the threshold for critical error on line slope 
#    interval in the amonut of time (in minutes) to go back and measure from
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

if (scalar @ARGV != 5 && scalar @ARGV != 4) {
	print STDERR join "' '", @ARGV, "\n";
	my $foo = 'check_rrd_data';
	exit;
}

# Default

# no defaults yet...

# Get parameters into variables
my $rrdfile = $ARGV[0] if (-r $ARGV[0]);           
my $ds = defined $ARGV[1]?$ARGV[1]:0;
my $warn = defined $ARGV[2] ? $ARGV[2] : 0;
my $crit = defined $ARGV[3] ? $ARGV[3] : 0;
my $in_interval = defined $ARGV[4] ? $ARGV[4] : 0;

# convert to seconds
my $interval=$in_interval*60;

# Find out last update time
my ($last) = RRDs::last ($rrdfile);
# print "\$last: ","$last\n";

# Calculate the start time to use 
my $starttime=$last-$interval;

# Fetch the starting data point
my ($start,$step,$names,$data) = RRDs::fetch ($rrdfile,"AVERAGE","-s",$starttime,"-e",$starttime);

# Assign the starting value
my $i;
my $found_index;
for ($i= 0; $i < @$names; $i++) {
        if (@$names[$i] eq $ds) {
            $found_index = $i;
            last;
        }
}
my $start_value = @$data[0]->[$found_index];

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

my $diff=$value-$start_value;
# print"Diff = ", $diff,"\n";


# And the slope. Note units in seconds...

my $slope=$diff/$interval;

# Ok, got the value we wanted....
# First check for critical errors
if ($slope >= $crit) {
	printf "RRD CRITICAL - Values Inceasing at rate of %.4f per second ", $slope;
	exit 2;		# Critical
}

# Check for warnings
if ($slope >= $warn) {
	printf "RRD WARNING - Values Increasing at rate of %.4f per second ", $slope; 
	exit 1;		# Warning
}

# Normally returns 0 (OK)
printf "RRD Reference Check OK - Rate of change is %.4f per second ", $slope;
exit 0
