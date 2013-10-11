#!/usr/bin/perl -w

##
## this script is based on script that was downloaded from
##  http://bergs.biz/blog/2007/05/08/monitor-number-of-active-connections-to-mysql-using-nagios/
##  
## it allows to check any numeric status variable SHOW GLOBAL STATUS LIKE '${var}'
##
## Depends on:
##  USED to utils.pm from nagios-plugins. I moved %ERRORS in here to avoid dependency
##  Getopt::Std
##
## History:
##  0.1 - ??? - 
##            - use warnings
##            - update nagios plugin location
##            - fix password option
##            - -v option for the status name
## 0.2 - ???  -
##            - add sig alarm timout 15 sec
##            - fix password and user options. only use them if not empty 
## 0.3 - 4/22/08
##            - add Host and port options
use strict;
use warnings;
use Getopt::Std;

# mng: ScR 1 - remove extra dependency upon nagios plugins. Move %ERRORS here.
#use lib "/home/mgorelik/nagios-plugins-1.4.11/plugins-scripts";
#use utils qw(%ERRORS);
my %ERRORS = ('UNKNOWN' , '-1',
              'OK' , '0',
              'WARNING', '1',
              'CRITICAL', '2');

use vars qw/ %opt /;
sub debug($);

my $TIMEOUT = 15;

#mng: add host and port options
getopts('c:dhp:u:w:Vv:P:H:', \%opt);

if (exists $opt{h}) {
    usage();
    exit(0);
}

if (exists $opt{V}) {
    print '$Id: check_mysql_status.pl v0.3 4/18/2008', "\n";
    exit(0);
}

my $debug = 0;
if (exists $opt{d}) {
    print "Enabling debug mode...\n";
    $debug = 1;
}

my $critical_threshold = 10;
if (exists $opt{c}) {
    $critical_threshold = $opt{c};
}
debug("\$critical_threshold=$critical_threshold\n");

my $warn_threshold = 5;
if (exists $opt{w}) {
    $warn_threshold = $opt{w};
}
debug("\$warn_threshold=$warn_threshold\n");

my $username = "";
my $username_opt = "";  
if (exists $opt{u}) {
    $username = $opt{u};
    if ( $username ) { 
       $username_opt = " -u $username";
    }
}

my $password = "";
my $password_opt = "";
if (exists $opt{p}) {
    $password = $opt{p};
    if ( $password ) {
       $password_opt = "-p$password";
    }
}

#mng: allows to cpecify status variable
my $variable = "Threads_running";
if (exists $opt{v}) {
   if( $opt{v} )
   {
     $variable = $opt{v};
   }
   else
  {
    print "Unknown: Must specify non empty variable name\n";
    exit $ERRORS{'UNKNOWN'};
  }
}

my $host="";
my $host_opt = "";
if (exists $opt{H}) {
    $host = $opt{H};
    if ( $host ) {
       $host_opt = "-h $host";
    }
}

my $port="";
my $port_opt = "";
if (exists $opt{P}) {
    $port = $opt{P};
    if ( $port ) {
       $port_opt = "-P $port";
    }
}


if ( $debug) {printf "user[%s] pwd[%s] variable[%s] port[%s] host[%s]\n", $username, $password, $variable, $port, $host;}

#
# build mysql command
#
my $cmd = qq(/bin/echo "SHOW GLOBAL STATUS LIKE '${variable}';" \| /usr/bin/mysql $host_opt $port_opt $username_opt $password_opt 2>/dev/null \| /bin/grep "${variable}";);

if ( $debug ) {print "q[$cmd]\n";}

#
# mng: Borrowed from check_mysql.pl
#
# Just in case of problems, let's not hang Nagios
$SIG{'ALRM'} = sub {
     print ("ERROR: No response from MySQL server (alarm)\n");
     exit $ERRORS{"UNKNOWN"};
};
alarm($TIMEOUT);


#
#run and parse the query
#
my $query_output = `$cmd`;
debug("\$query_output=\"$query_output\"\n");
unless ($query_output =~ /^$variable\s+(\d+)\s+$/) {
    print "Unknown: Unable to read output from MySQL\n";
    exit $ERRORS{'UNKNOWN'};
}

my $value = $1;
debug("\$value=$value\n");

if ($value > $critical_threshold) {
    print "Critical: $value $variable\n";
    exit $ERRORS{'CRITICAL'}
} elsif ($value > $warn_threshold) {
    print "Warning: $value $variable\n";
    exit $ERRORS{'WARNING'}
} else {
    print "OK: $value $variable\n";
    exit $ERRORS{'OK'}
}



###########################################################################

sub usage {
    if (@_ == 1) {
	print "$0: $_[0].\n";
    }
    print << "EOF";
Usage: $0 [options]
  -c THRESHOLD
     critical threshold for number of active connections (default: 10)
  -d
     enable debug mode (mutually exclusive to -q)
  -h
     display usage information
  -p PASSWORD
     The password to use when connecting to the server.
  -u USERNAME
     The MySQL username to use when connecting to the server.
  -V
     display version number      
  -w THRESHOLD
     Warning threshold for number of active connections (default: 5)
  -v STATUS_VARIABLE
     Specify numeric status variable name here. e.g Threads_running
  -H host
  -P port
EOF
}

sub debug($) {
    if ($debug) {
	print STDERR $_[0];
    }
}
