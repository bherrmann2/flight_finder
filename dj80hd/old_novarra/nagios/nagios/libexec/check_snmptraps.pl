#!/usr/local/groundwork/bin/perl --

#
#	Get SNMP Traps summary for this host
use CollageQuery ;
use strict;

my $debug = 0;
my $hostName = $ARGV[0];
my $history = $ARGV[1];		# Start time from now, in hours, to count events
my $warning = $ARGV[2];		# Number of warning events to set warning status
my $critical = $ARGV[3];	# Number of critical events to set critical status

if (!$history) {	$history = 24;}
if (!$warning) {	$warning = 1;}
if (!$critical) {	$critical = 1;}
my $t;
if ($t=CollageQuery->new()) {
	print "New CollageQuery object.\n" if $debug;
} else {
	print "Error: connect to CollageQuery failed!\n";
	exit 2;
}
my $start = time;
my $dateType = "LastInsertDate";
my $startTime  = time_text(time - ($history*60*60));	# Set start time
my $endTime = time_text(time);	# Set end time
my $applicationType = "SNMPTRAP";
print "\nSample getEventsForDevice method with applicationType $applicationType\n" if $debug;
print "Getting events for host $hostName, $dateType from $startTime to $endTime.\n" if $debug;
my $ref = $t->getEventsForDevice($hostName,$dateType,$startTime,$endTime,$applicationType);
if (!$ref) {
	print "No $applicationType events found for $hostName.";
	exit 0;
}
my $count = 0;
my %status_count = ();
foreach my $event (keys %{$ref}) {
	if ($debug) {
		print "\tEvent=$event\n";
		foreach my $attribute (keys %{$ref->{$event}}) {
			print "\t\t$attribute=".$ref->{$event}->{$attribute}."\n";
		}
		$count++;
	}
	if ($ref->{$event}->{OperationStatus} !~ /ACCEPTED/) {
		$status_count{$ref->{$event}->{MonitorStatus}}++;
	}
}
print "Found $count events for getEventsForHost\n" if $debug;
print "Elapsed time = ".(time - $start)."\n" if $debug;
my $outstring = "SNMPTRAP Count by Status: ";
my $exitcode = 0;
foreach my $key  (keys %status_count) {
	$outstring .= "$key=$status_count{$key},"
}
$outstring =~ s/,$//;
$t->destroy();
if ($status_count{CRITICAL} >= $critical) {
	$outstring = "CRITICAL: ".$outstring;
	$exitcode = 2 ;
} elsif ($status_count{WARNING} >= $warning) {
	$outstring = "WARNING: ".$outstring;
	$exitcode = 1;
} else {
	$outstring = "OK: ".$outstring;
}
print $outstring;
exit $exitcode;

sub time_text {
		my $timestamp = shift;
		if ($timestamp <= 0) {
			return "0";
		} else {
			my ($seconds, $minutes, $hours, $day_of_month, $month, $year,$wday, $yday, $isdst) = localtime($timestamp);
			return sprintf "%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$month+1,$day_of_month,$hours,$minutes,$seconds;
		}
}
__END__



