#!/usr/local/groundwork/bin/perl -w
#
# $Id$
#
# This is a plugin for monitoring IBM db2 databases
#
# Copyright 2004 - 2005 GroundWork OpenSource Solutions
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Revision History
#	Harper Mann 15-Dec-2005
#	  Added low thresholds
#	Harper Mann 25-Oct-2005
#	  Initial Revision
#
use strict;

require 5.003;

use Getopt::Long;

# DBI and DBD-DB2 Perl modules
use DBI;
use DBD::DB2;

use utils qw($TIMEOUT %ERRORS &print_revision &support);

use vars qw($VERSION $PROGNAME $logfile $debug $state);
use vars qw($dbh $database $username $password $message);
use vars qw($sql $sth);
use vars qw($privsok $opt_warn $opt_crit);
use vars qw($low_warn $high_warn $low_crit $high_crit);
use vars qw($check_select $opt_select $newline $perfdata);

$VERSION = $1;
$0 =~ m!^.*/([^/]+)$!;
$PROGNAME = $1;

# Read cmdline opts:
Getopt::Long::Configure('bundling');
GetOptions (
	"V|version"				=> \&print_version,
	"h|help"				=> \&print_help,
	"v|verbose" 			=> \$debug,
	"u|user=s" 				=> \$username,
	"n|newline" 			=> \$newline,
	"p|passwd=s" 			=> \$password,
	"b|database=s"			=> \$database,
	"s|select-statement:s"  => \$opt_select,
	"P|perfdata"  			=> \$perfdata,
	"w|warn:s"  			=> \$opt_warn,
	"c|crit:s"  			=> \$opt_crit
);

# This is the list of built-in error values.  Experimental...
# low_warn:high_warn,low_crit:high_crit
my %error_vals = (
	AGENTS_STOLEN 			  => '10:20,5:25',
	SORT_OVERFLOWS 			  => '1000:1500,500:3000',
	HASH_JOIN_SMALL_OVERFLOWS => '10:20,5:35',
	HASH_JOIN_OVERFLOWS 	  => '10:20,5:35',
	LOCK_ESCALS 			  => '10:20,5:35',
	X_LOCK_ESCALS 			  => '10:20,5:35',
	DEADLOCKS 				  => '5:10,0:25',
	FILES_CLOSED 			  => '10:20,5:35',
	AGENTS_WAITING 			  => '5:10,0:25',
	AGENTS_REGISTERED 		  => '40:50,30,70',
	POOLS 					  => '80000000:100000000,70000000:120000000',
	PAGES 					  => '4000000:5000000,3000000:6000000',
	TOTAL_CONS 				  => '40000:60000,30000:70000',
	WRITES 					  => '400000000:500000000,300000000:600000000'
);

# List of sql statements to get monitoring values.  Note the keys match 
# the error vals above.
my %select_list = (
	AGENTS_STOLEN => 
		'SELECT AGENTS_STOLEN FROM TABLE(SNAPSHOT_APPL(\'\',-1)) AS SNAPSHOT',
	SORT_OVERFLOWS =>
  		'SELECT SORT_OVERFLOWS FROM TABLE(SNAPSHOT_DATABASE(\'\',-1)) AS SNAPSHOT',
	HASH_JOIN_SMALL_OVERFLOWS => 
  		'SELECT HASH_JOIN_SMALL_OVERFLOWS FROM TABLE(SNAPSHOT_APPL(\'\',-1)) AS SNAPSHOT',
	HASH_JOIN_OVERFLOWS =>
		'SELECT HASH_JOIN_OVERFLOWS FROM TABLE(SNAPSHOT_APPL(\'\',-1)) AS SNAPSHOT',
	LOCK_ESCALS => 
		'SELECT LOCK_ESCALS FROM TABLE(SNAPSHOT_APPL(\'\',-1)) AS SNAPSHOT',
	X_LOCK_ESCALS => 
		'SELECT X_LOCK_ESCALS FROM TABLE(SNAPSHOT_APPL(\'\',-1)) AS SNAPSHOT',
	DEADLOCKS =>
		'SELECT DEADLOCKS FROM TABLE(SNAPSHOT_APPL(\'\',-1)) AS SNAPSHOT',
	FILES_CLOSED => 
		'SELECT FILES_CLOSED FROM TABLE(SNAPSHOT_BP(\'\',-1)) AS SNAPSHOT',
	AGENTS_WAITING => 
		'SELECT AGENTS_WAITING_ON_TOKEN FROM TABLE(SNAPSHOT_DBM(-1)) AS SNAPSHOT',
	AGENTS_REGISTERED =>
		'SELECT AGENTS_REGISTERED FROM TABLE(SNAPSHOT_DBM(-1)) AS SNAPSHOT',
	POOLS =>
		'SELECT POOL_DATA_P_READS,POOL_INDEX_P_READS,POOL_DATA_L_READS,POOL_INDEX_L_READS FROM TABLE(SNAPSHOT_BP(\'\',-1)) AS SNAPSHOT',
	PAGES =>
		'SELECT TOTAL_PAGES,USED_PAGES FROM TABLE(SNAPSHOT_TBS_CFG(\'\',-1)) AS SNAPSHOT',
	TOTAL_CONS =>
		'SELECT TOTAL_CONS FROM TABLE(SNAPSHOT_DATABASE(\'\',-1)) AS SNAPSHOT',
	WRITES =>
		'SELECT POOL_WRITE_TIME,POOL_ASYNC_WRITE_TIME FROM TABLE(SNAPSHOT_DATABASE(\'\',-1)) AS SNAPSHOT'
);

sub usage();

# Check args.  It's okay not to supply user/pass cause the env may have it
if (!$database) {
	print "Database not specified\n"; usage();exit $ERRORS{"UNKNOWN"} 
}

if ($opt_warn) {
	($low_warn,$high_warn) = split(/:/, $opt_warn);
	if ($low_warn > $high_warn) {
		print "Warning low thresholds can't be greater than high\n";
		usage();
		exit $ERRORS{"UNKNOWN"};
	}
}

if ($opt_crit) {
	($low_crit,$high_crit) = split(/:/, $opt_crit);
	if ($low_crit > $high_crit) {
		print "Warning low thresholds can't be greater than high\n";
		usage();
		exit $ERRORS{"UNKNOWN"};
	}
}

# connect to the instance...
$dbh = dbConnect($database,$username,$password);

$state = check_select($opt_select) if ($privsok);

if ($debug) {
	$message="$database: ";
	$message=$message . "ok. " . getDbVersion($dbh)	unless ($state);
	print "$message\n";
}

exit $state;

#############################################################################
sub print_perf() {
}

sub usage () {
	print "Usage: $PROGNAME -v (verbose) -u <user> -p <passwd> -b <database>
    [-s <select value>] [-w <low:high>] [-c <low:high>] -P (perfdata)
    $PROGNAME [-V|--version]
    $PROGNAME [-h|--help]
";
}

sub print_help {
 	print_revision($PROGNAME,'$Revision$'); #'
	print "
This plugin checks DB2 database health.

Options:
 -v, --verbose
     More verbose output
 -u, --user=STRING
     db2 user
 -p, --passwd=STRING
     db2 password
 -s, --select-value=COLUMN
     the column to retrieve from the table function call
 -n, --newline
     Output newlines after values so it's readable.  Also shows OK values
      (Don't use with Nagios)
 -P, --perfdata
     Output performance data
 -w, --warn=WARNING
     WARNING(range): Range specification for warning threshold
 -c, --crit=CRITICAL
     CRITICAL(range): Range specification for critical threshold
\n";
	exit $ERRORS{"UNKNOWN"};
}


sub print_version {
	print_revision($PROGNAME,'$Revision$'); #'
	exit $ERRORS{"OK"};
}


sub dbConnect {
	my $db = shift;
	my $user = shift;
	my $pass = shift;

	# Make connection to the database.
	print "dbi:db2:$db $user $pass\n" if $debug;
	my $source = "dbi:DB2:$db";
	if ($user) {
		$dbh = DBI->connect($source,$user,$pass,{ LongReadLen => 102400 } );
	} else {
		# Environment has access? try it...
		$dbh = DBI->connect($source,"","",{ LongReadLen => 102400 } );
	}
	if (!defined($dbh)) { print "db connect failed\n" if $debug; exit; }

	# check to be sure this user has "SELECT" privilege.
	if (checkPriv("SELECT") < 1) {
		$message="user $username needs \"SELECT\" privilege.";
		$state=$ERRORS{"UNKNOWN"};
	} else {
		$privsok = 1;
 		$state=$ERRORS{"OK"};
	}
	return ($dbh);
}


sub getDbVersion {
	my $dbh = shift;
	my $db2version;

	$sql = "select * from SYSIBM.SYSVERSIONS";

	$sth = $dbh->prepare($sql);
	$sth->execute() || die "Select failed: $!\n";
	($db2version) = $sth->fetchrow_array();
	$sth->finish();

	return $db2version;
}


sub checkPriv {
	my ($privilege,$yesno);
	$privilege = shift;
	
	$sql = "SELECT COUNT(*) FROM SYSIBM.SQLTABLEPRIVILEGES WHERE PRIVILEGE = '$privilege'";  
	$sth=$dbh->prepare($sql);
	$sth->execute() || die "Privilege select failed: $!\n";
	$yesno = $sth->fetchrow_array();
	$sth->finish();

	return($yesno);
}

my $perf;
my $ok;
sub check_select {
	my $svalue = shift;
	my $retvalsum = 0;
	my ($retval,@row,$result,$p_result,$status,$res, $str);

	if ($svalue) {
		# Just run the one requested
	  	$sql = $svalue;
		print "$sql\n" if $debug;

		$sth=$dbh->prepare($sql);
		$sth->execute();

		while (@row = $sth->fetchrow()) {
            print "@row\n" if $debug;
			$result .= check_one_val($sql,@row)
		}
	} else {
		# Run the built-in list from select_list
		while (my ($key, $value) = each(%select_list)) {
			print "$value\n" if $debug;

			$sth=$dbh->prepare($value);
			$sth->execute() || die "List select failed: $!\n";

			while (@row = $sth->fetchrow()) {
				print "@row\n" if $debug;
				$str = check_vals($key,@row);
 				$result .= $str if $str;
			}
		}
	}

	if ($result && $result =~ /Critical/i) {
		print "DB2 status CRITICAL - ";
		$status = $ERRORS{'CRITICAL'};
	} elsif ($result && $result =~ /Warning/i) {
		print "DB2 status WARNING - ";
		$status = $ERRORS{'WARNING'};
	} else {
		print "DB2 status OK - ";
		$status = $ERRORS{'OK'}; 
		if ($newline) { $result = $ok }
				 else { $result = "All indicators are within thresholds" }
	}
	if ($newline) { print "\n" }
 	print $result;

	if ($perfdata) { print "| $perf" }
	print "\n";

	$sth->finish();

	return $status;
}

# Didn't get a single arg so roll through the default list
sub check_vals {
	my $key = shift;
	my @row = shift;
	my ($result,$val,$crit,$warn);

	($warn,$crit) = split(/,/, $error_vals{$key});
	($low_warn,$high_warn) = split(/:/, $warn);
	if ($low_warn > $high_warn) {
		print "Warning low thresholds can't be greater than high\n";
		usage();
		exit $ERRORS{"UNKNOWN"};
	}
	($low_crit,$high_crit) = split(/:/, $crit);
	if ($low_crit > $high_crit) {
		print "Warning low thresholds can't be greater than high\n";
		usage();
		exit $ERRORS{"UNKNOWN"};
	}

	foreach $val (@row) { 
		if ($val > $high_crit) { 
			$result .= "$key: $val ($crit Critical High) " }
		elsif ($val < $low_crit) { 
			$result .= "$key: $val ($crit Critical Low) " }
		elsif ($val > $high_warn) { 
			$result .= "$key: $val ($crit Warning High) " }
		elsif ($val < $low_warn) { 
			$result .= "$key: $val ($warn Warning Low) " }
		$ok .= "$key: $val (Ok) ";
	}

	if (!$val) { $val = '0' }
	$perf .= "$key=$val;$warn;$crit;; ";

	$result = $result . "\n" if $newline && $result;
	$ok = $ok . "\n" if $newline && $ok;
	return $result;
}

# Got an arg that is wanted so just do that one
sub check_one_val {
	my $sql = shift;
	my @row = shift;
	my ($result,$val,$one);

	($one, $sql) = split(/ /, $sql);

	foreach $val (@row) { 
		if ($val > $high_crit) { 
			$result .= "Critical High: $sql: $val ($opt_crit) " }
		elsif ($val > $low_crit) {
			$result .= "Critical Low: $sql: $val ($opt_warn) "}
		elsif ($val > $high_warn) {
			$result .= "Warning High: $sql: $val ($opt_warn) "}
		elsif ($val > $low_warn) {
			$result .= "Warning Low: $sql: $val ($opt_warn) "}
		$ok .= "$sql: $val (Ok) ";
	}

	if (!$val) { $val = '0' }
	$perf .= "$sql=$val;$opt_warn;$opt_crit;; ";

	$result = $result . "\n" if $newline && $result;
	$ok = $ok . "\n" if $newline && $ok;
	return $result;
}
