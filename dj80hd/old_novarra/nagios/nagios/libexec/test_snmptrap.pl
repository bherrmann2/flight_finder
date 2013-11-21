#!/usr/local/groundwork/bin/perl --

# Test program for Collage package
#use lib "/usr/local/groundwork/perl-api";
use CollageQuery ;
#print Collage->getHostGroups()."\n";

# Alternative use
# use Collage qw(getHostGroups);
# print getHostGroups()."\n";

my $t;
my $start = time;
if ($t=CollageQuery->new()) {
	print "New CollageQuery object.\n";
} else {
	die "Error: connect to CollageQuery failed!\n";
}



$start = time;
print "\nSample getEventsbyDate method with applicationType SNMPTRAP\n";
#$getparam1 = "192.168.2.203";
$getparam1 = "localhost";
$getparam2 = "LastInsertDate";
$getparam3  = time_text(time - (365*24*60*60));	# Set start time
$getparam4 = time_text(time);	# Set start time
$getparam5 = "SNMPTRAP";
print "Getting events $getparam2 from $getparam3 to $getparam4 for ApplicationType $getparam5.\n";
my $ref = $t->getEventsbyDate_TEST($getparam2,$getparam3,$getparam4,$getparam5);
my $count = 0;
foreach my $event (keys %{$ref}) {
	print "\tEvent=$event\n";
	foreach my $attribute (keys %{$ref->{$event}}) {
		print "\t\t$attribute=".$ref->{$event}->{$attribute}."\n";
	}
	$count++;
}
print "Found $count events for getEventsbyDate\n";
print "Elapsed time = ".(time - $start)."\n";


$start = time;
$getparam2 = "LastInsertDate";
#$getparam3 = "2005-10-21 16:17:24";
$getparam3  = time_text(time - (365*24*60*60));	# Set start time
$getparam4 = time_text(time);	# Set start time
$getparam5 = "localhost";
$getparam6 = "SNMPTRAP";
print "\nSample getEventsForHost method with applicationType $getparam6\n";
print "Getting events for host $getparam5, $getparam2 from $getparam3 to $getparam4.\n";
my $ref = $t->getEventsForHost($getparam5,$getparam2,$getparam3,$getparam4,$getparam6);
my $count = 0;
foreach my $event (keys %{$ref}) {
	print "\tEvent=$event\n";
	foreach my $attribute (keys %{$ref->{$event}}) {
		print "\t\t$attribute=".$ref->{$event}->{$attribute}."\n";
	}
	$count++;
}
print "Found $count events for getEventsForHost\n";
print "Elapsed time = ".(time - $start)."\n";


$start = time;
print "\nSample getEventsForDevice method with applicationType SNMPTRAP\n";
#$getparam1 = "192.168.2.203";
$getparam1 = "localhost";
$getparam2 = "LastInsertDate";
#$getparam3 = "2005-10-21 16:17:24";
#$getparam4 = "2005-10-29 16:17:24";
$getparam5 = "SNMPTRAP";
print "Getting events for device $getparam1, $getparam2 from $getparam3 to $getparam4.\n";
my $ref = $t->getEventsForDevice($getparam1,$getparam2,$getparam3,$getparam4,$getparam5);
my $count = 0;
foreach my $event (keys %{$ref}) {
	print "\tEvent=$event\n";
	foreach my $attribute (keys %{$ref->{$event}}) {
		print "\t\t$attribute=".$ref->{$event}->{$attribute}."\n";
	}
	$count++;
}
print "Found $count events for getEventsForDevice\n";
print "Elapsed time = ".(time - $start)."\n";



sub time_text {
		my $timestamp = shift;
		if ($timestamp <= 0) {
			return "0";
		} else {
			my ($seconds, $minutes, $hours, $day_of_month, $month, $year,$wday, $yday, $isdst) = localtime($timestamp);
			return sprintf "%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$month+1,$day_of_month,$hours,$minutes,$seconds;
		}
}





$t->destroy();


exit;
__END__


