#!/usr/local/groundwork/bin/perl --
#
# Database updater for Application log files
# Based on check_log2.pl by Aaron Bostick (abostick@mydoconline.com)
# Written by  Thomas Stocking (tstocking@itgroundwork.com)
# Added a counter to early terminate if > $throttle lines matched to reduce the load
# Last modified: 03-30-2006
#
# Thanks and acknowledgements to Ethan Galstad for Nagios and the check_log
# plugin this is modeled after.
#
# Usage: check_syslog_gw.pl 
#				-l <log_file> 
#				-s <seek_file> 
#				-x <regular expression file>
#				-a <ipaddress of host>
#				-n the regex file contains 'all no match'
#
# Description:
#
# This script will read logfiles and compare each line with the regular expressions
# listed in the regular expression file. If there is a match, a log message will be 
# created in the Foundation datatbase.
# If the log file name does not match an IP address, the IP address specified in the -a 
# flag will be used.
#


BEGIN {
    if ($0 =~ s/^(.*?)[\/\\]([^\/\\]+)$//) {
        $prog_dir = $1;
        $prog_name = $2;
    }
}

require 5.004;

use lib qq(/usr/local/groundwork/nagios/libexec);
use lib $main::prog_dir;
use utils qw($TIMEOUT %ERRORS &print_revision &support &usage);
use Getopt::Long;
use IO::Socket;
use CollageQuery;

sub print_usage ();
sub print_version ();
sub print_help ();

# Initialize strings
my $debug = 0;	
my $log_file = '';
my $seek_file = '';
my $script_revision = '$Revision$ ';
my $serverip = '';
my $host = '';
my $remote_host="localhost";
my $remote_port = 4913;
my $thisnagios = "localhost";

# Grab options from command line
GetOptions
("l|logfile=s"      => \$log_file,
 "s|seekfile=s"     => \$seek_file,
 "x|regx_file=s"    => \$regx_file,
 "a|ipaddress=s"    => \$ipaddress,
 "b|host=s"         => \$host,
 "n|negate-test"    => \$negate,
 "v|version"        => \$version,
 "h|help"           => \$help);

!($version) || print_version ();
!($help) || print_help ();

# Make sure log file is specified
($log_file) || usage("Log file not specified.\n");
# Make sure seek file is specified
($seek_file) || usage("Seek file not specified.\n");

my @regx_list = read_regxfile($regx_file);

if ($debug) {
	print "Regular expression list:\n";
	foreach my $tmp (@regx_list) {
		print $tmp."\n";
	}
}
######################################################################
#
#	This section attempts to get the IP address using DNS
#		Commented out.
######################################################################
# Get ip address from input parms if supplied
#if ($ipaddress =~ m/(\d+\.\d+\.\d+\.\d+)/) {
#    print "ip address = $1\n" if $debug;
#    $serverip = $1;
#	$host = gethostbyaddr(inet_aton($serverip), AF_INET);  
## Or get server IP from logfile name
#} elsif ($log_file =~ m/(\d+\.\d+\.\d+\.\d+)/) {
#	$serverip = $1;
#	$host = gethostbyaddr(inet_aton($serverip), AF_INET);  
## Or assume log_file name is host name, not IP address. Do lookup of hostname to get IP
#} elsif ($log_file =~ m/.*\/(\S+)\.log$/) {
#	$host = $1;
#	print "host name $host" if $debug;
##	$serverip = inet_ntoa(inet_aton($host));
#	$serverip = inet_aton($host);
#	if (!$serverip) {
#		print "Error: Unknown ip address or host name for $log_file. Contact the system administrator.\n"; 
#		exit 3;
#	}
#	$serverip = inet_ntoa($serverip);
#	print " ip address = $serverip\n" if $debug;
#} else {
#	print "Unknown ip address or host name for $log_file. Contact the system administrator.";
#	exit 3;
#}
##########################################################################
######################################################################
#
#	This section attempts to get the IP address from Monarch
#		
######################################################################
# If no host supplied
if (!$host) {
	# Get hosts->IPaddress from Monarch 
	my ($Database_Name,$Database_Host,$Database_User,$Database_Password) = CollageQuery::readGroundworkDBConfig("monarch");
	my $dbh = DBI->connect("DBI:mysql:$Database_Name:$Database_Host", $Database_User, $Database_Password) ;
	if ($dbh) {
		my $query = "select name,address from hosts where address=\"$ipaddress\"; ";
		my $sth = $dbh->prepare($query);
		$sth->execute() or die  $@;
		while (my $row=$sth->fetchrow_hashref()) {
			$host = $$row{name};
		} 
		$sth->finish();
		$dbh->disconnect();
	}
}
$serverip = $ipaddress;
if (!$host) {
	$host = $ipaddress;
}

######################################################################
# Open log file
open LOG_FILE, $log_file || die "Unable to open log file $log_file: $!";

# Try to open log seek file.  If open fails, we seek from beginning of
# file by default.
if (open(SEEK_FILE, $seek_file)) {
	chomp(@seek_pos = <SEEK_FILE>);
	close(SEEK_FILE);

	#  If file is empty, no need to seek...
	if ($seek_pos[0] != 0) {
	
		# Compare seek position to actual file size.  If file size is smaller
		# then we just start from beginning i.e. file was rotated, etc.
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat(LOG_FILE);

		if ($seek_pos[0] <= $size) {
			seek(LOG_FILE, $seek_pos[0], 0);
		}
	}
}
my $socket = IO::Socket::INET->new(PeerAddr => $remote_host,
						PeerPort => $remote_port,
						Proto    => "tcp",
					   Type     => SOCK_STREAM)
	or die "Can't open TCP socket $remote_port to host $remote_host\n";
my %monthhash = ("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06",
						"Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
# Look for these message types
my %msgtypes = (	);	# Not used for this parser
my $matchcount = 0;
my $counter = 0;
my $throttle = 300;
# Loop through every line of log file and output database update line.
while ($line = <LOG_FILE>) {
# Parse line
	chomp $line;
	my $msgtype; 
	my $component; 
	my $month;
	my $mday;
	my $time;
	my $text;
	my $matchflag = 0;
	my $notmatchflag = 0;

	if ($line =~ /(\w+)\s+(\d+)\s(\d\d:\d\d:\d\d)\s(.*?)\s(.*?):(.*)/) {
		$msgtype=$5; 
		$component=$4; 
		$month=$1; 
		$mday=sprintf "%02d",$2; 
		$time=$3; 
		$text=$6;
		#print "$month $mday $time msgtype=$msgtype, component=$component, $text \n" if $debug;

		# look for the negatives; if one matches, this line is OK
		if ($negate) {
			$notmatchflag = 0;
			foreach my $tmp (@regx_list) {
				my $regx = qr/$tmp/;
				if ($line =~ /$regx/i) {
					print "one of the negative regex was seen, $line passes\n" if $debug;
					$notmatchflag = 1;
					last;
				}
			}
			if (!$notmatchflag) {
				$severity = "CRITICAL";
				$matchflag = 1;
				$matchcount++;	
			}

		# if the negate flag is not passed, look for positive matches
		} else {
			foreach my $tmp (@regx_list) {
				my $regx = qr/$tmp/;
				#if ($text =~ /$regx/i) x
				if ($line =~ /$regx/i) {
					$severity = "CRITICAL";
					$matchflag = 1;
					$matchcount++;
				}
			}
		}
	} 
	if (!$matchflag) {
		#print "No match for line $line\n";
		next;
	}
#	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $year = (localtime)[5] + 1900;
	my $datetime="$year-$monthhash{$month}-$mday $time"; # Use current year. No year in log!
#	$txtmessage = "/usr/local/groundwork/gwlogdb/gwlogdb_syslog.sh action=insert typerule=SERVICE ";
#	$txtmessage .= "component=SYSLOG subcomponent=\"$component\" severity=$severity appname=Sun_SysLog errortype=\"$msgtype\" ";
#	$txtmessage .= "ip=$serverip msg=\"$text\" ";
	# translate $severity to $monitorstatus
	my $monitorstatus = $severity;
	my $xml_message = "<SYSLOG consolidation='SYSLOG' ";	# Start message tag.  Consolidation is ON
# 	my $xml_message = "<SYSLOG ";
	$xml_message .= "MonitorServerName=\"$thisnagios\" ";			# Default Identification 
# Device should always be IP everywhere
	$xml_message .= "Device=\"$serverip\" ";					# Default Identification 
# Nagios construct - ignored by syslog rules
	$xml_message .= "Host=\"$host\" ";					# Default Identification 
	$xml_message .= "Severity=\"$severity\" ";	
	$xml_message .= "MonitorStatus=\"$monitorstatus\" ";	
	$xml_message .= "ReportDate=\"".time_text(time)."\" ";	# set ReportDate to current local time
#	$xml_message .= "LastInsertDate=\"".time_text(time)."\" ";	# set ReportDate to current local time
	$xml_message .= "LastInsertDate=\"$datetime\" ";	
	$xml_message .= "ipaddress=\"$serverip\" ";
	$xml_message .= "ErrorType=\"$msgtype\" ";
	$xml_message .= "SubComponent=\"$msgtype\" ";
	$text =~ s/\n/ /g;
	$text =~ s/<br>/ /ig;
	$text =~ s/["']/&quot;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	$xml_message .= "TextMessage=\"$text\" ";	
	$xml_message .= "/>";			# End message tag
	print $xml_message."\n" if $debug;
	print $socket $xml_message;

	# Now send the passive check result to Nagios
	send_to_nagios($host,$severity,$text);

	if ($counter++ > $throttle) {last;}
}
CommandClose($socket);
close($socket);

# Overwrite log seek file and print the byte position we have seeked to.
open(SEEK_FILE, "> $seek_file") || die "Unable to open seek count file $seek_file: $!";
print SEEK_FILE tell(LOG_FILE);

# Close seek file.
close(SEEK_FILE);
# Close the log file.
close(LOG_FILE);

#	Call sub to print summary of syslog messages in gwlogdb for this ip address 
if ($matchcount > 0) {
	print "WARNING: Matched $matchcount messages. | $matchcount\n";
	exit 1;
} else {
	print "OK: Matched no messages. | 0\n";
	exit 0;
}
#print_gwlog_summary($serverip,$host);
#exit;


#
# Subroutines
#
sub CommandClose {
	my $socket = shift;
# Create XML stream - Format:
#	<SERVICE-MAINTENANCE     command="close" /> 
	my $xml_message = "<SERVICE-MAINTENANCE command=\"close\" />";	
#	print $xml_message."\n\n" if $debug;
	print $socket $xml_message;
	return;
}

sub print_usage () {
    print "Usage: $prog_name -l <log_file> -s <log_seek_file> \n";
    print "Usage: $prog_name [ -v | --version ]\n";
    print "Usage: $prog_name [ -h | --help ]\n";
}

sub print_version () {
    print_revision($prog_name, $script_revision);
    exit $ERRORS{'OK'};
}

sub print_help () {
    print_revision($prog_name, $script_revision);
    print "\n";
    print "Send syslog messages into the GroundWork Foundation database\n";
    print "\n";
    print_usage();
    print "\n";

	print '
	 Usage: check_syslog_gw.pl 
				-l	<log_file> 
				-s	<seek_file> 
				-x	<regular expression file>
				-a	<ipaddress of host>
				-b	<host>
				-v	<version>
				-h	<help>

	Description:
	This script will read logfiles and compare each line with the regular expressions
	listed in the regular expression file. If there is a match, a log message will be 
	created in the Foundation datatbase.
	If the log file name does not match an IP address, the IP address specified in the -a 
	flag will be used.
	';
    print "\n";
    support();
    exit $ERRORS{'OK'};
}

sub time_text {
		my $timestamp = shift;
		if ($timestamp <= 0) {
			return "none";
		} else {
			my ($seconds, $minutes, $hours, $day_of_month, $month, $year,$wday, $yday, $isdst) = localtime($timestamp);
			return sprintf "%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$month+1,$day_of_month,$hours,$minutes,$seconds;
		}
}

sub read_regxfile {
	my $regxfile = shift;
	my @regx_list = ();
	open (REGXFILE,$regxfile) or die "Can't open parsing definition file $regxfile";
#	Valid regular expression lines - Ignore everything after #
	while (my $line=<REGXFILE>) {
		chomp $line;
		if ($line =~ /^\s*#/) { next }
		if ($line =~ /^\s*(\S.*\S)\s*$/) { 
			push @regx_list,$1;
			#print "pushing $1 \n";
		 }
	}
	close REGXFILE;
	return @regx_list;
}



sub print_gwlog_summary {
	my $ipaddress=shift;
	my $host=shift;
	if (!$ipaddress) {
			print "Error: IP address not defined.\n";
			exit 2;
	}
	my $t;
	if ($t=CollageQuery->new()) {
		print "New CollageQuery object.\n" if $debug;;
	} else {
		die "Error: connect to CollageQuery failed!\n";
	}
	print "\nSample getEventsForHost method with applicationType SYSLOG\n" if $debug;
	my $starttime = time_text(time - (60*60*24));	# set start time to 24 hours ago
	my $endtime = time_text(time);
	print "Getting events for host $host, LastInsertDate from $starttime to $endtime.\n" if $debug;
	my $ref = $t->getEventsForDevice($ipaddress,"LastInsertDate",$starttime,$endtime,"SYSLOG");
	my %count = ();
	foreach my $event (keys %{$ref}) {
	#	print "\tEvent=$event\n";
		#foreach my $attribute (keys %{$ref->{$event}}) {
			#print "\t\t$attribute=".$ref->{$event}->{$attribute}."\n";
		#}
		$count{$ref->{$event}->{"MonitorStatus"}}++;
	}
	#print "Found $count events for getEventsForHost\n";
	$t->destroy();
	my $statusmsg = "";
	foreach my $key (keys %count) {
		$statusmsg .= "$key=$count{$key}, ";
	}
	if ($statusmsg) {
		$statusmsg = "Message counts by severity: ".$statusmsg;
	} else {
		$statusmsg = "No messages for this server";
	}
	if ($count{FATAL} or $count{HIGH} or $count{CRITICAL}) {
			$statusmsg = "CRITICAL ".$statusmsg.$lastmsg;
			print "$statusmsg\n";
			exit 2;
	} elsif ($count{SERIOUS} or $count{WARNING}) {
			$statusmsg = "WARNING ".$statusmsg.$lastmsg;
			print "$statusmsg\n";
			exit 1;
	} else {
			$statusmsg = "OK. No errors. $statusmsg. $lastmsg\n";
			print $statusmsg;
			exit 0;
	}
	return;
}

#
#	Send to Nagios command pipe
#	
sub send_to_nagios {
	my $host = shift;
	my $sev = shift;
	my $msg = shift;
	my $nagios_cmd_pipe = "/usr/local/groundwork/nagios/var/spool/nagios.cmd";
	my $service_last = "syslog_last";
	my $echo_cmd = "/bin/echo";
	my $nagiossev = 3;
	if ($sev eq "CRITICAL") {
		$nagiossev = 2;
	} elsif ($sev eq "WARNING") {
		$nagiossev = 1;
	} elsif ($sev eq "OK") {
		$nagiossev = 1;
	} 
	if (stat($nagios_cmd_pipe)) {
		my $datetime = time;
		my $cmdline = "[$datetime] PROCESS_SERVICE_CHECK_RESULT;$host;$service_last;$nagiossev;$msg";
		my @lines = `$echo_cmd "$cmdline" >> $nagios_cmd_pipe`;
	} else {
		if (open LOG,">>$logfile") {
			print LOG "Can't stat nagios command pipe $nagios_cmd_pipe\n";
			close LOG;
		}
	}
	return;
}




