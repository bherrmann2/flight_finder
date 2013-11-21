#!/usr/local/groundwork/bin/perl --
# $Id: check_oracle_instance.pl,v 1.1.1.1 2005/02/07 19:33:32 hmann Exp $

#  Copyright (c) 2002  Sven Dolderer
#  some pieces of Code adopted from Adam vonNieda's oracletool.pl
#                                      (http://www.oracletool.com)
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.

#   This software is provided without warranty of any kind.
# Modified 3-31-2006 H Kriel for GroundWork
# Removed check for session privileges, made redundant as Tain-Yule Wu provides
# one time all purpose guarantee of access per request 3-31-3006
# Modified 10-6-2006 D Blunt for GroundWork
# Modified code to return results to standard out even if results are within
# normal bounds.  Also modified code to output performance data.
# 

require 5.003;

use strict;
use Getopt::Long;

# We need the DBI and DBD-Oracle Perl modules:
require DBI || die "It appears that the DBI module is not installed! aborting...\n";
require DBD::Oracle || die "It appears that the DBD::Oracle module is not installed! aborting...\n";

# Set the environment variable as required by Oracle Client installation
$ENV{'ORACLE_HOME'}="/u01/app/oracle/oracle/product/10.2.0/db_1";
$ENV{'LD_ASSUME_KERNEL'}="2.6.9";
$ENV{'TNS_ADMIN'}="/u01/app/oracle/oracle/product/10.2.0/db_1/network/admin";

use vars qw($VERSION $PROGNAME $logfile $debug $state $dbh $database $username $password $message $sql $cursor $opt_asession $opt_nsession $opt_tablespace $opt_nextents $opt_fextents $opt_aextents $privsok $warn $critical);

use vars qw($opt_psession $opt_locks $opt_segments $opt_aprocs);

'$Revision: 1.1.1.1 $' =~ /^.*(\d+.\d+) \$$/;  # Use The Revision from RCS/CVS
$VERSION = $1;
$0 =~ m!^.*/([^/]+)$!;
$PROGNAME = $1;
$debug="true";
$logfile = "/usr/local/groundwork/nagios/var/check_oracle_instance.log";
my %ERRORS = (UNKNOWN => -1, OK => 0, WARNING => 1, CRITICAL => 2);

`date >> /tmp/oracheck.log`;
`env >> /tmp/oracheck.log`;

# Read cmdline opts:
Getopt::Long::Configure('bundling', 'no_ignore_case');
GetOptions (
         "V|version"    => \&version,
         "h|help"       => \&usage,
         "u|user=s" => \$username,
         "p|passwd=s" => \$password,
         "c|connect=s" => \$database,
         "a|active-sessions:s"  => \$opt_asession,
         "s|num-sessions:s"  => \$opt_nsession,
         "t|tablespaces:s" => \$opt_tablespace,
         "n|num-extents:s" => \$opt_nextents,
         "f|free-extents:s" => \$opt_fextents,
         "x|allocate-extents" => \$opt_aextents,
         "y|process-sessions" => \$opt_psession,
         "l|blocking-locks" => \$opt_locks,
         "g|segments" => \$opt_segments,
         "i|active-processes" => \$opt_aprocs
        );
($database && $username && $password) || die "mandatory parameters missing (try -h)\n";
logit("    \$opt_asession = \"$opt_asession\"");
logit("    \$opt_nsession = \"$opt_nsession\"");
logit("    \$opt_tablespace = \"$opt_tablespace\"");
logit("    \$opt_nextents = \"$opt_nextents\"");
logit("    \$opt_fextents = \"$opt_fextents\"");
logit("    \$opt_aextents = \"$opt_aextents\"");

logit("    \$opt_psession = \"$opt_psession\"");
logit("    \$opt_locks = \"$opt_locks\"");
logit("    \$opt_segments = \"$opt_segments\"");
# so let's connect to the instance...
$dbh = dbConnect($database,$username,$password);

$message="$database: ";
check_sessions($opt_nsession)   if ($opt_nsession && $privsok);
check_sessions($opt_asession,"# active")   if ($opt_asession && $privsok);
check_tablespaces($opt_tablespace)   if ($opt_tablespace && $privsok);
check_nextents($opt_nextents)   if ($opt_nextents && $privsok);
check_fextents($opt_fextents)   if ($opt_fextents && $privsok);
check_aextents()   if ($opt_aextents && $privsok);
check_sessions_2($opt_psession)   if ($opt_psession && $privsok);
check_locks_2($opt_locks)  if ($opt_locks && $privsok);
check_segments_2 ($opt_segments)  if ($opt_segments && $privsok);
check_active_processes_2 ($opt_aprocs)  if ($opt_aprocs && $privsok);

#$message=$message . "ok. " . getDbVersion($dbh)   unless ($state);
print "$message\n";
exit $state;


sub usage {
   copyright();
   print "
This plugin will check various things of an oracle database instance.

Prerequisties are: a local oracle client,
                   perl > v5.003, and DBI and DBD::Oracle perl modules.

Usage: $PROGNAME -u <user> -p <passwd> -c <connectstring>
          [-a <w>/<c>] [-s <w>/<c>] [-t <w>/<c>] [-n <w>/<c>] [-f <w>/<c>] [-x]
       $PROGNAME [-V|--version]
       $PROGNAME [-h|--help]
";
   print "
Options:
 -u, --user=STRING
    the oracle user
 -p, --passwd=STRING
    the oracle password
 -c, --connect=STRING
    the oracle connectstring as defined in tnsnames.ora
 -a, --active-sessions=WARN/CRITICAL
    check the number of active (user-)sessions
      WARN(Integer): number of sessions to result in warning status,
      CRITICAL(Integer): number of sessions to result in critical status
 -s, --num-sessions=WARN/CRITICAL
    check the total number of (user-)sessions
      WARN(Integer): number of sessions to result in warning status,
      CRITICAL(Integer): number of sessions to result in critical status
 -t, --tablespaces=WARN/CRITICAL
    check the percent of used space in every tablespace
      WARN(Integer): percentage to result in warning status,
      CRITICAL(Integer): percentage to result in critical status
 -n, --num-extents=WARN/CRITICAL
    check the number of extents of every object (excluding SYS schema)
      WARN(Integer): number of extents to result in warning status,
      CRITICAL(Integer): number of extents to result in critical status
 -f, --free-extents=WARN/CRITICAL
    check the number of free extents of every object: max_extents - #extents
      WARN(Integer): number of free extents to result in warning status,
      CRITICAL(Integer): number of free extents to result in critical status
 -x, --allocate-extents
    warn if an object cannot allocate a next extent.
 -y, --process-sessions
		check to see if the number of sessions is approaching the maximum limit of processes.
 -l, --blocking-locks
		  check if the number of blocking locks > 2, or number of locks > number of dml locks * .6
 -g, --segments
		  check non-cache segments if (max_extents - extents) < .20 * max_extents
	  ";
   exit $ERRORS{"UNKNOWN"};
}


sub version {
   copyright();
   print "
$PROGNAME $VERSION
";
   exit $ERRORS{"UNKNOWN"};
}


sub copyright {
   print "The Nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute
copies of the plugins under the terms of the GNU General Public License.
For more information about these matters, see the file named COPYING.
Copyright (c) 2002 Sven Dolderer\n";
}


sub logit {
   my $text = shift;
   if ($debug) {
      open (LOG,">>$logfile") || die "Cannot open log file \"$logfile\"!";
      print LOG "$text\n";
      close (LOG);
   }
}


sub dbConnect {
   logit("Enter subroutine dbConnect");

   my $database = shift;
   my $username = shift;
   my $password = shift;

# Attempt to make connection to the database..
   my $data_source = "dbi:Oracle:$database";
   $dbh = DBI->connect($data_source,$username,$password,{PrintError=>0});

# Show an error message for these errors.
# ORA-12224 - "The connection request could not be completed because the listener is not running."
# ORA-01034 - "Oracle was not started up."
# ORA-01090 - "Shutdown in progress - connection is not permitted""
# ORA-12154 - "The service name specified is not defined correctly in the TNSNAMES.ORA file."
# ORA-12505 - "TNS:listener could not resolve SID given in connect descriptor."
# ORA-12545 - "TNS:name lookup failure."

   unless ($dbh) {
         logit("      Error message is ~$DBI::errstr~");
         if ( $DBI::errstr =~ /ORA-01017|ORA-1017|ORA-01004|ORA-01005/ ) {
            $message="Login error: ~$DBI::errstr~";
	    $state=$ERRORS{"UNKNOWN"};
         } elsif ( $DBI::errstr =~ /ORA-12224/ ) {
            $message= "You received an ORA-12224, which usually means the listener is down, or your connection definition in your tnsnames.ora file is incorrect. Check both of these things and try again.";
	    $state=$ERRORS{"CRITICAL"};
         } elsif ( $DBI::errstr =~ /ORA-01034/ ) {
            $message= "You received an ORA-01034, which usually means the database is down. Check to be sure the database is up and try again.";
	    $state=$ERRORS{"CRITICAL"};
         } elsif ( $DBI::errstr =~ /ORA-01090/ ) {
            $message= "You received an ORA-01090, which means the database is in the process of coming down.";
	    $state=$ERRORS{"CRITICAL"};
         } elsif ( $DBI::errstr =~ /ORA-12154/ ) {
            $message= "You received an ORA-12154, which probably means you have a mistake in your TNSNAMES.ORA file for the database that you chose.";
	    $state=$ERRORS{"UNKNOWN"};
         } elsif ( $DBI::errstr =~ /ORA-12505/ ) {
            $message= "You received an ORA-12505, which probably means you have a mistake in your TNSNAMES.ORA file for the database that you chose, or the database you are trying to connect to is not defined to the listener that is running on that node.";
	    $state=$ERRORS{"UNKNOWN"};
         } elsif ( $DBI::errstr =~ /ORA-12545/ ) {
            $message= "You received an ORA-12545, which probably means you have a mistake in your TNSNAMES.ORA file for the database that you chose. (Possibly the node name).";
	    $state=$ERRORS{"UNKNOWN"};
         } else {
            $message="Unable to connect to Oracle ($DBI::errstr)\n";
	    $state=$ERRORS{"UNKNOWN"};
         }
	 
   } else {
         logit("      Login OK.");

         # check to be sure this user has "SELECT ANY TABLE" privilege.
         #logit("      checking for \"SELECT ANY TABLE\" privilege");
         logit("      skip checking for \"SELECT ANY TABLE\" privilege");
         #if (checkPriv("SELECT ANY TABLE") < 1) {
         #   $message="user $username needs \"SELECT ANY TABLE\" privilege.";
         #   $state=$ERRORS{"UNKNOWN"};
         #} else {
            $privsok="yep";
	    $state=$ERRORS{"OK"};
         #}
   }
   return ($dbh);
}


sub getDbVersion {

   logit("Enter subroutine getDbVersion");

   my $dbh = shift;
   my $oraversion;

# Find out if we are dealing with Oracle7 or Oracle8
   logit("   Getting Oracle version");
   $sql = "select banner from v\$version where rownum=1";

   $cursor = $dbh->prepare($sql) or logit("Error: $DBI::errstr");
   $cursor->execute;
   (($oraversion) = $cursor->fetchrow_array);
   $cursor->finish;
   logit("   Oracle version = $oraversion");
   return $oraversion;
}


sub checkPriv {
   logit("Enter subroutine checkPriv");
   my ($privilege,$yesno);
   $privilege = shift;
   logit("   Checking for privilege \"$privilege\"");
   
   $sql = "SELECT COUNT(*) FROM SESSION_PRIVS WHERE PRIVILEGE = '$privilege'";  
   $cursor=$dbh->prepare($sql);
   $cursor->execute;
   $yesno = $cursor->fetchrow_array;
   $cursor->finish;

   return(1);
}


sub get_values {
   logit("Enter subroutine get_values");
   my ($args, $inverse, $abort);
   $args = shift;
   $inverse = shift;
   if ($args =~ m!^(\d+)/(\d+)$!) {
     $warn = $1;
     $critical = $2;

     # TODO: check for positive numbers!
     
     if (! $inverse && $warn >= $critical) {
        print "\"$args\": warning threshold must be less than critical threshold. aborting...\n";
	$abort="yep";
     }
     if ($inverse && $warn <= $critical) {
        print "\"$args\": warning threshold must be greater than critical threshold. aborting...\n";
	$abort="yep";
     }
   } else {
     print "\"$args\": invalid warn/critical thresholds. aborting...\n";
     $abort="yep";
   }
   exit $ERRORS{"UNKNOWN"}  if $abort;
   logit ("      args=$args, warn=$warn, critical=$critical");
}


sub check_sessions {
   logit("Enter subroutine check_sessions");
   my ($args, $add, $sqladd, $count);
   $args = shift;
   $add = shift || '#';   # Default: Number of sessions
   $sqladd = "AND STATUS = 'ACTIVE'"   if ($add eq "# active");

   get_values($args);
   
   $sql = "SELECT COUNT(*) FROM V\$SESSION WHERE TYPE <> 'BACKGROUND' $sqladd";  
   $cursor=$dbh->prepare($sql);
   $cursor->execute;
   $count = $cursor->fetchrow_array;
   $cursor->finish;
   logit ("      $add sessions is $count");

   $state=$ERRORS{"OK"};
   if ($count >= $critical) {
      $message = $message . "CRITICAL: ";
      $state=$ERRORS{"CRITICAL"};
   } elsif ($count >= $warn) {
      $message = $message . "WARNING: ";
      $state=$ERRORS{"WARNING"}  if $state < $ERRORS{"WARNING"};
   } else {
      $message = $message . "OK: ";
   }
   $message = $message . "$add sessions = $count | sessions=$count;$warn;$critical;0;";
}


sub check_tablespaces {
   logit("Enter subroutine check_tablespaces");
   my ($args, $tablespace, $pctused, $mymsg, $mywarn, $mycritical, $myok, $myperf);
   $args = shift;

   get_values($args);
   
   $sql = "SELECT
     DF.TABLESPACE_NAME \"Tablespace name\",
     NVL(ROUND((DF.BYTES-SUM(FS.BYTES))*100/DF.BYTES),100) \"Percent used\"
   FROM DBA_FREE_SPACE FS,
    (SELECT TABLESPACE_NAME, SUM(BYTES) BYTES FROM DBA_DATA_FILES GROUP BY
     TABLESPACE_NAME ) DF
   WHERE FS.TABLESPACE_NAME (+) = DF.TABLESPACE_NAME
   GROUP BY DF.TABLESPACE_NAME, DF.BYTES
   ORDER BY 2 DESC";

   $cursor=$dbh->prepare($sql);
   $cursor->execute;

   $myperf="";

   $state=$ERRORS{"OK"};
   while (($tablespace, $pctused) = $cursor->fetchrow_array) {
      logit ("      $tablespace - $pctused% used");
      if ($pctused >= $critical) {
         unless ($mycritical) {
           $mymsg = $mymsg . "CRITICAL: Tablespace usage: ";
	   $mycritical="yep";
	 }
         $mymsg = $mymsg . "$tablespace ($pctused%) ";
         $state=$ERRORS{"CRITICAL"};
      } elsif ($pctused >= $warn) {
         unless ($mywarn) {
           $mymsg = $mymsg . "WARNING: Tablespace usage: ";
	   $mywarn="yep";
	 }
         $mymsg = $mymsg . "$tablespace ($pctused%) ";
         $state=$ERRORS{"WARNING"}  if $state < $ERRORS{"WARNING"};
      } else {
	unless ($myok) {
          $mymsg = $mymsg . "OK: Tablespace usage: ";
          $myok="yep";
        }
        $mymsg = $mymsg . "$tablespace ($pctused%) ";
      }
      $myperf=$myperf . " '$tablespace'=$pctused%;$warn;$critical;0;100";
   }
   $cursor->finish;
   $message = $message . $mymsg . "|" . $myperf;
#. "   "   if ($mycritical || $mywarn);
}


sub check_nextents {
   logit("Enter subroutine check_nextents");
   my ($args, $owner, $objname, $objtype, $extents, $mymsg, $mywarn, $mycritical, $myok, $myperf);
   $args = shift;

   get_values($args);
   
   $sql = "SELECT
             OWNER              \"Owner\",
             SEGMENT_NAME       \"Object name\",
             SEGMENT_TYPE       \"Object type\",
             COUNT(*)           \"Extents\"
           FROM DBA_EXTENTS WHERE OWNER <> 'SYS'
             GROUP BY SEGMENT_TYPE, SEGMENT_NAME, TABLESPACE_NAME, OWNER
             HAVING COUNT(*) >= $warn
             ORDER BY 4 DESC";

   $cursor=$dbh->prepare($sql);
   $cursor->execute;
   
   $myperf="";

   while (($owner, $objname, $objtype, $extents) = $cursor->fetchrow_array) {
      if ($extents >= $critical) {
         unless ($mycritical) {
           $mymsg = $mymsg . "CRITICAL: # Extents: ";
           $mycritical="yep";
         }
         $mymsg = $mymsg . "$owner.$objname($objtype)=$extents ";
         $state=$ERRORS{"CRITICAL"};
      } elsif ($extents >= $warn) {
         unless ($mywarn) {
           $mymsg = $mymsg . "WARNING: # Extents: ";
           $mywarn="yep";
         }
         $mymsg = $mymsg . "$owner.$objname($objtype)=$extents ";
         $state=$ERRORS{"WARNING"}  if $state < $ERRORS{"WARNING"};
      } else {
         unless ($myok) {
	   $mymsg = $mymsg . "OK: # Extents: ";
           $myok="yep";
         }
         $mymsg = $mymsg . "$owner.$objname($objtype)=$extents ";
      }
      $myperf=$myperf . " '$owner.$objname($objtype)'=$extents;$warn;$critical;0;";
   }
   $cursor->finish;
   $message = $message . $mymsg . "|" . $myperf;
#"   "   if ($mycritical || $mywarn);
}


sub check_fextents {
   logit("Enter subroutine check_fextents");
   my ($args, $owner, $objname, $objtype, $extents, $maxextents, $freextents, $mymsg, $mywarn, $mycritical, $myok, $myperf);
   $args = shift;

   get_values($args, "inverse");
   
   $sql = "SELECT
      OWNER                        \"Owner\",
      SEGMENT_NAME                 \"Object name\",
      SEGMENT_TYPE                 \"Object type\",
      EXTENTS                      \"Extents\",
      MAX_EXTENTS                  \"Max extents\",
      MAX_EXTENTS - EXTENTS        \"Free extents\"
   FROM DBA_SEGMENTS
      WHERE (EXTENTS + $warn) >= MAX_EXTENTS
      AND SEGMENT_TYPE != 'CACHE'
      ORDER BY 6";

   $cursor=$dbh->prepare($sql);
   $cursor->execute;

   $myperf="";

   $state=$ERRORS{"OK"};
   while (($owner, $objname, $objtype, $extents, $maxextents, $freextents) = $cursor->fetchrow_array) {
      if ($freextents <= $critical) {
         unless ($mycritical) {
           $mymsg = $mymsg . "CRITICAL: Free extents: ";
           $mycritical="yep";
         }
         $mymsg = $mymsg . "$owner.$objname($objtype)=$extents ";
         $state=$ERRORS{"CRITICAL"};
      } elsif ($freextents <= $warn) {
         unless ($mywarn) {
           $mymsg = $mymsg . "WARNING: Free extents: ";
           $mywarn="yep";
         }
         $mymsg = $mymsg . "$owner.$objname($objtype)=$extents/$maxextents ";
         $state=$ERRORS{"WARNING"}  if $state < $ERRORS{"WARNING"};
      } else {
         unless ($myok) {
           $mymsg = $mymsg . "OK: Free extents: ";
           $mywarn="yep";
         }
         $mymsg = $mymsg . "$owner.$objname($objtype)=$extents/$maxextents ";
      }
      $myperf=$myperf . " '$owner.$objname($objtype)'=$freextents;$warn;$critical;0;";
   }
   $cursor->finish;
   if ($mywarn || $mycritical) {
     $message = $message . $mymsg . "|" . $myperf;
   } else {
     $message = $message . "OK: All extents above free extent thresholds.";
   }
#"   "   if ($mycritical || $mywarn);
}


sub check_aextents {
   logit("Enter subroutine check_aextents");
   my ($args, $owner, $objname, $objtype, $tablespace_name, $mymsg, $mywarn);
   my (@tablespaces);

   # Get a list of all tablespaces
   $sql = "SELECT TABLESPACE_NAME
           FROM DBA_TABLESPACES ORDER BY TABLESPACE_NAME";
   $cursor = $dbh->prepare($sql);
   $cursor->execute;
   while ($tablespace_name = $cursor->fetchrow_array) {
      push @tablespaces, $tablespace_name;
   }
   $cursor->finish;

   # Search every tablespace for objects which cannot allocate a next extent.
   foreach $tablespace_name(@tablespaces) {
      logit ("        checking tablespace $tablespace_name");
      $sql = "SELECT
	   OWNER            \"Owner\",
	   SEGMENT_NAME     \"Object name\",
	   SEGMENT_TYPE     \"Object type\"
	FROM DBA_SEGMENTS
	   WHERE TABLESPACE_NAME = '$tablespace_name'
	   AND NEXT_EXTENT > (SELECT NVL(MAX(BYTES),'0') FROM DBA_FREE_SPACE
			      WHERE TABLESPACE_NAME = '$tablespace_name')";
      $cursor = $dbh->prepare($sql);
      $cursor->execute;

      $state=$ERRORS{"OK"};
      while (($owner, $objname, $objtype) = $cursor->fetchrow_array) {
         logit ("        found: $owner.$objname($objtype)");
         unless ($mywarn) {
           $mymsg = $mymsg . "WARNING: cannot allocate a next extent: ";
           $mywarn="yep";
         }
         $mymsg = $mymsg . "$owner.$objname($objtype) ";
         $state=$ERRORS{"WARNING"}  if $state < $ERRORS{"WARNING"};
      }
      $cursor->finish;
   }
   if ($mywarn) {
     $message = $message . $mymsg;
   } else {
     $message = $message . "OK: No tables where an extent cannot be allocated.";
   }
}



sub check_sessions_2 {
   logit("Enter subroutine check_sessions_2");
	$sql = "select sysdate, name from v\$database";
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my ($v_date,$v_dbname) = $cursor->fetchrow_array;
	$cursor->finish;
	logit ("      sysdate is $v_date");
	logit ("      name is $v_dbname");
	$sql = "select count(*) from v\$session";
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my $v_sess_count = $cursor->fetchrow_array;
	$cursor->finish;
	logit ("     session count is $v_sess_count");

	$sql = "select value from v\$parameter where name='processes' " ;
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my $v_process  = $cursor->fetchrow_array;
	$cursor->finish;
	logit ("      processes is $v_process");
        $state=$ERRORS{"OK"};
	 if ($v_sess_count > ($v_process *.9)) {
		$message = $message . " Number of sessions $v_sess_count approaching the maximum limit $v_process.  ";
		$state=$ERRORS{"CRITICAL"};
	 } else {
		$message = $message . "OK: # sessions = $v_sess_count (limit = $v_process).";
         }
	$message = $message . "| sesscount=$v_sess_count;;;0;$v_process";
}


sub check_locks_2 {
   logit("Enter subroutine check_locks_2");
	my $v_lock_per = 60;
	$sql = "select sysdate, name from v\$database";
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my ($v_date,$v_dbname) = $cursor->fetchrow_array;
	$cursor->finish;
	logit ("      sysdate is $v_date");
	logit ("      name is $v_dbname");
	$sql = "select count(*) from v\$lock where sid > 10";
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my $v_lock = $cursor->fetchrow_array;
	$cursor->finish;
	logit ("     lock count is $v_lock");
	$sql = "select value from v\$parameter where name='dml_locks'  " ;
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my $v_dml_lock  = $cursor->fetchrow_array;
	$cursor->finish;

	$sql = "select count(*) from v\$lock where block=1 " ;
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my $v_block  = $cursor->fetchrow_array;
	$cursor->finish;
	logit ("     blocking count is $v_block");
        $state=$ERRORS{"OK"};
	if (($v_block > 2) or ($v_lock > ($v_dml_lock * $v_lock_per/100 ))) {
		$message = $message . "CRITICAL: # locks $v_lock with $v_block blocking locks out of total dml_lock $v_dml_lock.  ";
		$state=$ERRORS{"CRITICAL"};
	} else {
		$message = $message . "OK: # locks = $v_lock, blocking locks = $v_block, total dml_lock = $v_dml_lock.";
        }
        $message = $message . "| blockinglocks=$v_block;;;; locks=$v_lock;;;; dml_lock=$v_dml_lock;;;;";
}



sub check_segments_2 {
   logit("Enter subroutine check_segments_2");
 	$sql = "select owner , tablespace_name , segment_name	, segment_type , extents, max_extents ".
					" from dba_segments ".
					" where segment_type <> 'CACHE' and (max_extents - extents) < .20 * max_extents ".
					" order by segment_type, owner, tablespace_name, segment_name "
			;
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my $segment_text = "";
	while (my $row=$cursor->fetchrow_hashref()) { 
		$segment_text .= $$row{segment_name}.", ";
		logit ("      segment $$row{segment_name}:  owner=$$row{owner}, tblspce=$$row{tablespace_name}, segtype=$$row{segment_type}, ext=$$row{extents}, maxext=$$row{max_extents}");
	}
	$cursor->finish;
	if (!$segment_text) {
		$message = $message . "OK:  No objects near 80% max limit.";
		$state=$ERRORS{"OK"};
	} else {
		$message = $message . "CRITICAL:  Some objects > 80% max limit: $segment_text.";
		$state=$ERRORS{"CRITICAL"};
	}
}



sub check_active_processes_2 {
   logit("Enter subroutine check_active_processes_2");
 	$sql = "select  a.actprocs, b.value ".
				 " from (select count(*) actprocs from v\$process) a, (select value from v\$parameter where name like 'processes') b ".
				" where a.actprocs/b.value > .8 "
		;
	$cursor=$dbh->prepare($sql);
	$cursor->execute;
	my $active_count = 0;
	while (my $row=$cursor->fetchrow_hashref()) { 
		$active_count++;
		logit ("      actprocs $$row{actprocs}:  value=$$row{value}");
	}
	$cursor->finish;
	$state=$ERRORS{"OK"};
        my $myperf="actprocs=$active_count;0;0;0;";
	if ($active_count) {
		$message = $message . "CRITICAL: # active processes over 80% of max limit is $active_count.  ";
		$state=$ERRORS{"CRITICAL"};
	} else {
		$message = $message . "OK: # active processes = $active_count.";
        }
        $message = $message . "|" . $myperf;
}



__END__

#######################################################
select file_name from dba_data_files where autoextensible = 'YES';
if no files then 
   echo "No files in autoextend mode"
   exit 0
else
   echo "Some files in autoextend mode"
   exit 1
fi
#######################################################

select owner,object_name,object_type from dba_objects where status = 'INVALID';
   echo "${totno} Invalid objects"
   if [[ $totno -gt 20 ]]
   then exit 1
   else exit 0
   fi
#######################################################

select a.log_mode || ', autoarchive=' || b.value || '.' from  v\$database a, v\$parameter b where b.name = 'log_archive_start';
grep "FALSE" $outlog 1>/dev/null 2>&1
grep "NOARCHIVELOG" $outlog 1>/dev/null 2>&1
if [ ! FALSE and NOARCHIVELOG  ]
then
   exit 0
else
   exit 1
fi
#######################################################

DONE!!!
USEFUL, PRINT segment_name

  select owner , tablespace_name , segment_name
       , segment_type , extents, max_extents
  from dba_segments
  where segment_type <> 'CACHE' and (max_extents - extents) < .20 * max_extents
  order by segment_type, owner, tablespace_name, segment_name;

if [[ $? -eq 0 ]]
   echo "No objects near 80% max limit"
   exit 0
else
   echo "Some objects > 80% max limit"
   exit 1
fi

#######################################################

DONE!!!
USEFUL

select  a.actprocs, b.value
from (select count(*) actprocs from v\$process) a, (select value from v\$parameter where name like 'processes') b
where a.actprocs/b.value > .8;
if [[ $? -eq 0 ]]
then
   echo "# of act procs under 80% of max limit"
   exit 0
else
   echo "# of act procs over 80% of max limit"
   exit 1
fi
#######################################################

select  a.actssns, b.value
from (select count(*) actssns from v\$session) a, (select value from v\$parameter where name like 'sessions') b
where a.actssns/b.value > .8;
if [[ $? -eq 0 ]]
then
   echo "# of act ssns under 80% of max limit"
   exit 0
else
   echo "# of act ssns over 80% of max limit"
   exit 1
fi

#######################################################

select distinct f.tablespace_name, b.status
from   dba_data_files f, v\$backup b
where  b.status != 'NOT ACTIVE'
and    f.file_id = b.file#
order by f.tablespace_name;

grep "ERROR" $errorlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   echo "ERROR logging into database $db"
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 2
fi

egrep -v "and|^SQL>|TABLESPACE_NAME|STATUS|-----|from|select |order by|where" $spoollog >> $outlog
grep "no rows selected" $outlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   echo "No tablespaces offline"
   exit 0
fi
   
grep "ACTIVE" $outlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   echo "Database $1 being backed up."
   exit 0
else
   cat $outlog
   exit 2
fi

#########################################################
select a.tablespace_name tablespace_name
,      a.maxfree max_free
,      b.maxnext max_next
from   (select tablespace_name
        ,      max(bytes) maxfree 
        from   dba_free_space 
        group  by tablespace_name) a
,      (select tablespace_name
        ,      max(next_extent) maxnext 
        from   dba_segments 
        group  by tablespace_name) b
where  a.tablespace_name = b.tablespace_name 
and    a.maxfree < b.maxnext * 2;

grep "ERROR" $errorlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   echo "ERROR logging into database $db"
   exit 2
fi

egrep -v "and|^SQL>|name|max|dba|extents|segment|-----|from|select |order by|where" $spoollog >> $outlog
grep "no rows selected" $outlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   echo "No space critical objects"
   exit 0
else
   echo "Some objects can not grow 2+ extents"
   exit 1
fi

#########################################################

SELECT a.Tablespace_Name, 100*b.FBlocks/a.TBlocks AS SPFREE FROM (SELECT Tablespace_Name, SUM(Blocks) AS TBlocks FROM DBA_DATA_FILES GROUP BY Tablespace_Name) a, (SELECT Tablespace_Name,  SUM(Blocks) AS FBlocks FROM DBA_FREE_SPACE GROUP BY Tablespace_Name) b WHERE (a.Tablespace_Name = b.Tablespace_Name) and (100*b.FBlocks/a.TBlocks < 15);
if [[ $? -eq 0 ]]
then
   echo "ERROR logging into database $db"
   exit 2
fi
egrep -v "and|^SQL>|Tablespace_Name|SPFREE|-----|from|select |order by|where" $spoollog >> $outlog
grep "no rows selected" $outlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   echo "No tablespaces full"
   exit 0
else
   echo "Some tablespaces > 85% full"
   exit 1
fi




