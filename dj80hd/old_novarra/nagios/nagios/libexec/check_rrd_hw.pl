#!/usr/local/groundwork/bin/perl -wT
# check_rrd_hw.pl
# Based on check_rrd.pl by Harper Mann (hmann@comcast.net)
# Checks RRDs for linear trends with Nagios
# Uses the Holt-Winters algorythm for determining linear trend in data. 
#
# Requirements:
# An rrd must exist to check for trends in it's data. This is the reference rrd. 
# You will specify the reference rrd and data source name on the command line.
# You should know the reference rrd step time to accurately specifiy the reference interval. 
# The reference interval is simply the time (in minutes) to use in calulating the trend. 
# It must be at least 1x the step value of the reference rrd, and cannot exceed nx the step value,
# where n is the number of steps since data was initially collected.
# If you don't know or care, a small amount of accuracy and efficiency will be sacrificed.  
#
# Missing Data:
# Missing data in a trend calculation is handled by extrapolating existing data from all 
# measurements up to the point where data is missing. If no data is present 
# from the beginning of a reference interval, the interval will be shortened to provide 
# a more local trend using data that does exist.
#
# Note:
# As this plugin does a complete trend analysis each time it is run, care should be taken not to 
# specify too long a reference interval, or high cpu loads may result from 
# multiple services using this check, or checking trends too often. 
# 
# Example:
# check_rrd_hw -r my_cpu.rrd -rd 5min -w 80 -tw 120 -c 95 -tc 240 -i 60 -p
#
# will check the my_cpu.rrd file for the ds called 5min, and will go to warning if the predicted vaule
# is over 80 within 2 hours, and to critical if the predicted value is over 95 within 4 hours. 
# It considers the last 60 minutes in making the prediction. Positive values are the only ones that make sense# in this context (cpu %s), so the plugin will restrict it's predictions to positive real numbers. 
#
# usage:
#    check_rrd_hw.pl -r reference_rrdfile -rd ds -w warning -tw trendwarning  -c critical -tc trendcritical  -i interval -p
#
#    interval is how far back (in minutes) to use in trending 
#    warning is the threshold for the actual warning value, specifed as low:high. 
#	 Single values as re treated as high only
#
#	 trend warning is the time (in minutes) unitl the predicted value exceeds the warning level,
#	 at which the plugin results in a warning level  
#
#    critical is the threshold for the actual critical value, specifed as low:high. 
#	 Single values as re treated as high only
#
#	 trend critical is the time (in minutes) unitl the predicted value exceeds the actual critical level,
#	 at which the plugin results in a critical level
#	
#	 the -p restricts predictions to positive real numbers. 
#	
#	 Note: critical levels mst be outside warning levels and trendcritical times must be longer 
#	 than trendwarning times. Trendcitical conditions supercede trendwarning conditions. 
#
# To Do:
# Add -n for negative real restrictions. 
# Add facility for writing an rrd and producing a graph of actual and trend predicted values. 
#
# Copyright (c) 2000-2004 Thomas Stocking (tstocking@itgroundwork.com)
#
# This plugin is FREE SOFTWARE. No warrenty of any kind is implied or granted. 
# You may use this software under the terms of the GNU General Public License only.
# See http://www.gnu.org/copyleft/gpl.html and usage() below
#

#
#makes things work when run without install
use lib qw( ../perl-shared/blib/lib ../perl-shared/blib/arch );
# this is for after install
use lib qw( /usr/local/groundwork/lib/perl ../lib/perl /usr/local/groundwork/nagios/libexec);
use RRDs;
use strict;			# RRD:File and utils.pm don't like this
require 'utils.pm';
# Set up environment

$ENV{'PATH'} = "/bin:/usr/bin:/usr/local/groundwork/bin";
$ENV{'ENV'} = "";

# Initialize Variables
my @vals = undef;
my @skips = undef;
my @lines = undef;

my $warn = -1;
my $lo_warn = undef;
my $hi_warn = undef;
my $twarn = undef;
my $crit = -1;
my $lo_crit = undef;
my $hi_crit = undef;
my $tcrit = undef;
my $interval = 10;
my $starttime = 0; 
my $lasttime = 0;
my $dev = undef;
my $debug = 0;
my $positive = 0;
my $res = undef;
my $state = "OK";
# Weighting Constants
my $lambda0 = 0.5;
my $lambda1 = 0.5;

# Intermediate values
my $alpha;
my $alpha0;
my $alpha1;
my $beta;
my $beta0;
my $beta1;

# Read the command line options

use Getopt::Long;
use vars qw($opt_r $opt_R $opt_w $opt_W $opt_c $opt_C $opt_i $opt_D $opt_V $opt_h $opt_p);
use vars qw($PROGNAME);
#use lib "$utilsdir";
use utils qw($TIMEOUT %ERRORS &print_revision &support &usage);

sub print_help ();
sub print_usage ();

$PROGNAME = "check_rrd_hw";

Getopt::Long::Configure('bundling');
my $status = GetOptions
        ("V"   => \$opt_V, "Version"         => \$opt_V,
         "r=s" => \$opt_r, "reference_rrd=s"  => \$opt_r,
         "R=s" => \$opt_R, "reference_data_store=s"  => \$opt_R,
         "w=s" => \$opt_w, "warning=s"  => \$opt_w,
         "W=s" => \$opt_W, "trend_warning=s"  => \$opt_W,
         "c=s" => \$opt_c, "crittcal=s"  => \$opt_c,
         "C=s" => \$opt_C, "trend_crittcal=s"  => \$opt_C,
		 "i=s" => \$opt_i, "interval=s"  => \$opt_i,
 		 "p"  => \$opt_p, "positive"  => \$opt_p,
         "D"   => \$opt_D, "debug"            => \$opt_D,
         "h"   => \$opt_h, "help"            => \$opt_h);

if ($status == 0)
{
        print_usage() ;
        exit $ERRORS{'OK'};
}

# Debug switch
if ($opt_D) {
	$debug = 1;
}

# Positive constraint switch
if ($opt_p) {
	$positive = 1;
}
if ($opt_V) {
        print_revision($PROGNAME,'$Revision: 1.0 $'); #'
        exit $ERRORS{'OK'};
}

if ($opt_h) {print_help(); exit $ERRORS{'OK'};}

# Options checking
# Warning
if ($opt_w) {
	if ($opt_w =~ /:/){
		@vals = split /:/, $opt_w;
		($vals[0]) || usage("Invalid value: low warning: $opt_w\n");
		($vals[1]) || usage("Invalid value: high warning: $opt_w\n");
		$lo_warn = $vals[0] if ($vals[0] =~ /^[0-9]+$/);
		$hi_warn = $vals[1] if ($vals[1] =~ /^[0-9]+$/);
		($lo_warn) || usage("Invalid value: low warning: $opt_w\n");
		($hi_warn) || usage("Invalid value: high warning: $opt_w\n");
	} else {
		$lo_warn = undef;
		$hi_warn = $opt_w if ($opt_w =~ /^[0-9]+$/);
        ($hi_warn) || usage("Invalid value: warning: $opt_w\n");
	}
} else { print "No warning level defined\n" if $debug }

# Critical
if ($opt_c) {
    if ($opt_c =~ /:/){
        @vals = split /:/, $opt_c;
        ($vals[0]) || usage("Invalid value: low critical: $opt_c\n");
        ($vals[1]) || usage("Invalid value: high critical: $opt_c\n");
        $lo_crit = $vals[0] if (($vals[0] =~ /^[0-9]+$/) && ($vals[0] < $lo_warn));
        $hi_crit = $vals[1] if (($vals[1] =~ /^[0-9]+$/) && ($vals[1] > $hi_warn));
        ($lo_crit) || usage("Invalid value: low critical: $opt_c\n");
        ($hi_crit) || usage("Invalid value: high critical: $opt_c\n");
    } else {
        $lo_crit = undef;
        $hi_crit = $opt_c if (($opt_c =~ /^[0-9]+$/)&& ($opt_c > $hi_warn));
        ($hi_crit) || usage("Invalid value: critical: $opt_c\n");
    }
} else { print "No critical level defined\n" if $debug }


# Trend Warning
if ($opt_W) {
        $twarn = $opt_W if ($opt_W =~ /^[0-9]+$/);
        ($twarn) || usage("Invalid value: trend warning: $opt_W\n");
    } else { print "No trend warning level defined\n" if $debug }


# Trend Critical
if ($opt_C) {
        $tcrit = $opt_C if (($opt_C =~ /^[0-9]+$/) && ($opt_C > $twarn));
        ($tcrit) || usage("Invalid value: trend critical: $opt_C\n");
    } else { print "No trend critical level defined\n" if $debug }


# Default
# Get parameters into variables
my $ref_rrdfile = $opt_r if ($opt_r =~ /rrd/);		
my $ref_ds = $opt_R;           
my $in_interval = $opt_i;

# convert to seconds
$interval=$in_interval*60;

# Find out last update time
my ($last) = RRDs::last ($ref_rrdfile);
print "last: ","$last\n" if $debug;
print "interval: ","$interval\n" if $debug;


# Fetch the reference data
# Fetch all the data over the interval so we can work with arrays
$starttime=$last-$interval;
print "starttime: ","$starttime\n" if $debug;
my ($start,$step,$names,$data) = RRDs::fetch ($ref_rrdfile,"AVERAGE","-s",$starttime,"-e",$last);
my $i;
my $found_index;
for ($i= 0; $i < @$names; $i++) {
	if (@$names[$i] eq $ref_ds) {
    	$found_index = $i;
        print "dsname ","@$names[$i]\n" if $debug;
		last;
    }    
}
print "index: ","$found_index\n" if $debug;

#saving fetched values in array
my $rows = 0;
my $column = 0;
my $missing = 0;
my $pctundef =0;
my @values;
my @times;
my $time_variable = $start;
foreach my $line (@$data) {
# got to the end, but fetch still has some data so stop here
	if ($time_variable gt $last) {
		last;
	}   	
	$time_variable = $time_variable + $step;
	foreach my $val (@$line) {
    	if ($column eq $found_index) {
			$values[$rows] = $val;
			$times[$rows] = $time_variable;
#			print "  ", scalar localtime($time_variable), " ($time_variable) ";
#			print "$column ";
#         	printf "%12.1f ",$val;
#			print "\n";
			if (!$val) {
				$missing++;
			}
		}
		$column++;
	}
   	$rows++;
   	$column = 0;
}
# Find percentage of missing data
$pctundef = 100*$missing/$rows;
printf "%12.2f",$pctundef if $debug;
print "percent undefined\n" if $debug;
print "#rows = $rows\n" if $debug;

# Loop over the interval to find earliest 2 valid points and assign to reference values 
my $row = 0;
my $first = 0;
my $value;
while ($row < $rows) {
    print "row = $row\n" if $debug;
# 	print "first = $first\n" if $debug;
	$value = $values[$row];
    print "value = $value\n" if $debug;
    if (($row == $first) && (!$value)) {
		$first++;
	} else {
		if ($row == $first) {
# We are at first valid point - store it
			$beta0 = $value;
#			print "first value: \n" if $debug;
#			print "beta0 = $beta0\n" if $debug;
		} else {
			if (($row == $first+1) && (!$value)) {
# second point not there, give up on first point
				$first++;
				$first++;
			} else {
				if ($row == $first+1) {
# we are at the second data point - calculate and store them
					$alpha = $value;
					$beta = $value-$beta0;
#					print "second values: \n" if $debug;
#					print "alpha = $alpha\n" if $debug;
#					print "beta = $beta\n" if $debug;
				} else {
					if (!$value) {
# accomodate missing data with predicted based on past data
						$value = $alpha + $beta;
					}
# Now the general case - calculate the next iterative values
#                    print "alpha = $alpha\n" if $debug;
#                    print "beta = $beta\n" if $debug;
#					print "value = $value\n" if $debug;
					$alpha0 = $alpha;
					$alpha = $lambda0*$value + (1-$lambda0)*($alpha+$beta);
					if ($alpha < 0 && $positive) {
						$alpha = 0;
					}
					$beta = $lambda1*($alpha - $alpha0) + (1-$lambda1)*$beta;	
				}
			}
		}
	}
	$row++;
	next;
}
print "final value = $value\n" if $debug;
print "final alpha = $alpha\n" if $debug;
print "final beta = $beta\n" if $debug;

# Calculate intercept times with warning and critical thresholds
# First see if we are already there	 
my $worst =0;

if ($lo_crit && $value < $lo_crit) {
	$worst = $ERRORS{'CRITICAL'};
	$state = "CRITICAL";
}

if ($value > $hi_crit) {
    $worst = $ERRORS{'CRITICAL'};
    $state = "CRITICAL";
}
if ($lo_warn && $value < $lo_warn) {
    $worst = $ERRORS{'WARNING'} if $worst < $ERRORS{'CRITICAL'};
    $state = "WARNING" if $worst < $ERRORS{'CRITICAL'};
}

if ($value > $hi_warn) {
    $worst = $ERRORS{'WARNING'} if $worst < $ERRORS{'CRITICAL'};
    $state = "WARNING" if $worst < $ERRORS{'CRITICAL'};
}
#print "Thresholds:\n";
#print "lo_crit = $lo_crit\n" if $lo_crit;
#print "hi_crit = $hi_crit\n";
#print "lo_warn = $lo_warn\n" if $lo_warn;
#print "hi_warn = $hi_warn\n";

# Get out without doing any trending, since we are already over the top
if ($worst != $ERRORS{'OK'}) { 
	print "$state: Parameter $ref_ds is ";
    printf "%12.2f", $value;
    print "\n";
	exit ($worst);
}
# Otherwise, let's do some trending...
# Find the intercepts
# Are we headed up or down?
my $Crit;
my $Warn;
my $crit_int;
my $warn_int;
my $time_string;
if ($beta >= 0) {
	$Crit = $hi_crit;
	$Warn = $hi_warn;
} else { 
	if (!$positive) {
		$Crit = $lo_crit;
		$Warn = $lo_warn;
	} else {
		print "OK: Downward trend. No indication you will exceed the thresholds.\n";
		exit (0);
	}
}
$crit_int = $last+(($Crit-$alpha)/$beta)*$step;
$warn_int = $last+(($Warn-$alpha)/$beta)*$step;

# Now test for Trend Critial and warning
if ($crit_int >= ($last+($tcrit*60))) {
    $worst = $ERRORS{'CRITICAL'};
    $state = "CRITICAL";
}
if ($warn_int >= ($last+($twarn*60))) {
    $worst = $ERRORS{'WARNING'} if $worst < $ERRORS{'CRITICAL'};
    $state = "WARNING" if $worst < $ERRORS{'CRITICAL'};
}

# Exit with the right code
$time_variable = scalar localtime ($crit_int);
my $mins_left = ($crit_int-$last)/60; 
print "$state: I predict you will exceed the critical value at $time_variable, in ";
printf "%.0f", $mins_left;
print " minutes,";
$time_variable = scalar localtime ($warn_int);
$mins_left = ($warn_int-$last)/60;
print " and the warning value at $time_variable, in ";
printf "%.0f", $mins_left;
print " minutes\n";
exit ($worst);



 
# Usage sub
sub print_usage () {
        print "Usage: $PROGNAME 
	[-r ] (Reference RRD name and path)  
	[-R ] (Reference data store name) 
	[-w <low:high>] (actual warning threshold)
	[-W ] (Trend Warning - minutes) 
	[-c <low:high>] (actual critical threshold - must be outside -w range)
	[-C]  (Trend Critical - minutes. Must be higher than -W)
	[-p] (constrain to positive real values)
	[-i] (Trend interval to consider - minutes) 
	[-D] (debug) [-h] (help) [-V] (Version)\n";
}


# Help sub
sub print_help () {
        print_revision($PROGNAME,'$Revision: 1.0 $');
        print "Copyright (c) 2004 Thomas Stocking

Perl RRD Trend check plugin for Nagios

";
        print_usage();
        print "
-r, --reference_rrd
   The RRD which you want to check for trends
-rd, --reference_data_store
   Data store in reference rrd to check
-w, --warning
   Actual warning threshold <low:high>
-W, --trend_warning
   Time threshold for predicted warnings (in minutes). Set this to the amount of time within which a predicted warning will result in a warning state. 
-c, --critical 
	Actual critical threshold <low:high>
-C, --trend_critical
   Time threshold for predicted critical errors (in minutes). Set this to the amount of time within which a predicted critical error will result in a critical state.   
-p, --positive
   Set if you want to restrict data range considered to positive real values.
-D, --debug
   Turn on debugging.  (Verbose)
-h, --help
   Print help
-V, --Version
   Print version of plugin
";
}


