#! /usr/local/groundwork/bin/perl -w
#
# check_load_remote
#
# License Information:
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
############################################################################

use POSIX;
use strict;
use Getopt::Long;
use vars qw($host $opt_V $opt_h $opt_v $opt_l $opt_i $verbose $PROGNAME $opt_w $opt_e $opt_c $opt_t $opt_H $status $state $msg $msg_q $MAILQ $SHELL);
use lib  "/usr/local/groundwork/nagios/libexec/" ;
use utils qw(%ERRORS &print_revision &support &usage );


sub print_help ();
sub print_usage ();
sub process_arguments ();

$ENV{'PATH'}='';
$ENV{'BASH_ENV'}=''; 
$ENV{'ENV'}='';
$PROGNAME = "check_load_remote";

Getopt::Long::Configure('bundling');
$status = process_arguments();

if ($status){
	print "ERROR: processing arguments\n";
	exit $ERRORS{"UNKNOWN"};
}

$host = $opt_H;
my $CMD = "/usr/bin/uptime";   # need to determine based on remote system

$SIG{'ALRM'} = sub {
	print ("ERROR: timed out waiting for $CMD on $host\n");
	exit $ERRORS{"WARNING"};
};
alarm($opt_t);

## get cmd output from remote system

if (! open (OUTPUT, "$SHELL $host $CMD 2>/dev/null| " ) ) {
	print "ERROR: could not open $CMD on $host\n";
	exit $ERRORS{'UNKNOWN'};
}

# only first line is relevant in this iteration.
while (<OUTPUT>) {
	print $_ if $verbose;
	if (/load/) {
		my $avg = $2 if /load average: (\S{4}), (\S{4}), (\S{4})/i;
			$msg_q = $avg;
			print "msg_q = $msg_q warn=$opt_w crit=$opt_c\n" if $verbose;

			if ($msg_q < $opt_w) {
				$msg = "OK: load ($msg_q) is below threshold ($opt_w/$opt_c)";
				$state = $ERRORS{'OK'};
			} elsif ($msg_q >= $opt_w  && $msg_q < $opt_c) {
				$msg = "WARNING: load is $msg_q (threshold w = $opt_w)";
				$state = $ERRORS{'WARNING'};
			} else {
				$msg = "CRITICAL: load is $msg_q (threshold c = $opt_c)";
				$state = $ERRORS{'CRITICAL'};
			}
		last;
	}
}

close (OUTPUT); 
# declare an error if we also get a non-zero return code from load
# unless already set to critical
if ( $? ) {
	print "stderr = $? : $! \n" if $verbose;
	$state = $state == $ERRORS{"CRITICAL"} ? $ERRORS{"CRITICAL"} : $ERRORS{"UNKNOWN"}  ;
	print "error: $!\n" if $verbose;
}
## close cmd

# Perfdata support
print "$msg | load=$msg_q\n";
exit $state;


#####################################
#### subs


sub process_arguments(){
	GetOptions
		("V"   => \$opt_V, "version"	=> \$opt_V,
		 "v"   => \$opt_v, "verbose"	=> \$opt_v,
		 "h"   => \$opt_h, "help"	=> \$opt_h,
                 "e=s" => \$opt_e, "shell=s"    => \$opt_e,
                 "l=s" => \$opt_l, "login=s"    => \$opt_l,
                 "i=s" => \$opt_i, "identity=s"    => \$opt_i,
		 "w=f" => \$opt_w, "warning=f"  => \$opt_w,   # warning if above this number
		 "c=f" => \$opt_c, "critical=f" => \$opt_c,   # critical if above this number
		 "t=i" => \$opt_t, "timeout=i"  => \$opt_t,
	         "H=s" => \$opt_H, "hostname=s" => \$opt_H
		 );

	if ($opt_V) {
		print_revision($PROGNAME,'$Revision: 1.1 $ ');
		exit $ERRORS{'OK'};
	}

	if ($opt_h) {
		print_help();
		exit $ERRORS{'OK'};
	}

	if (defined $opt_v ){
		$verbose = $opt_v;
	}

        if (defined $opt_e ){
                if ( $opt_e eq "ssh" ) {
                    if (-x "/usr/local/bin/ssh") {
                        $SHELL = "/usr/local/bin/ssh";
                    } elsif ( -x "/usr/bin/ssh" ) {
                        $SHELL = "/usr/bin/ssh";
                    } else {
                        print_usage();
                        exit $ERRORS{'UNKNOWN'};
                    }
		    if (defined $opt_l ){
			$SHELL.=" -l $opt_l";
		    }
		    if (defined $opt_i ){
			$SHELL.=" -i $opt_i";
		    }
                } elsif ( $opt_e eq "rsh" ) {
                        $SHELL = "/usr/bin/rsh";
                } else {
                        print_usage();
                        exit $ERRORS{'UNKNOWN'};
                }
        } else {
           print_usage();
           exit $ERRORS{'UNKNOWN'};
        }


	unless (defined $opt_t) {
		$opt_t = $utils::TIMEOUT ;	# default timeout
	}

	unless (defined $opt_H) {
		print_usage();
		exit $ERRORS{'UNKNOWN'};
	}

	unless (  defined $opt_w &&  defined $opt_c ) {
		print_usage();
		exit $ERRORS{'UNKNOWN'};
	}

	if ( $opt_w >= $opt_c) {
		print "Warning cannot be greater than Critical!\n";
		exit $ERRORS{'UNKNOWN'};
	}

	return $ERRORS{'OK'};
}

sub print_usage () {
	print "Usage: $PROGNAME -e <shell> -H <hostname> [-w <warn>] [-c <crit>] [-l <login>] [-i <identity>] [-t <timeout>] [-v verbose]\n";
}

sub print_help () {
	print_revision($PROGNAME,'$Revision: 1.1 $');
	print "Copyright (c) 2004 jeff scott\n";
	print "\n";
	print_usage();
	print "\n";
	print "   Checks the five minute load average\n";
	print "   I chose five minute average to ignore spikes in cpu usage\n";
	print "-e (--shell)     = ssh or rsh (ssh highly recommended)\n";
	print "-H (--hostname)  = remote server name (required)";
	print "-w (--warning)   = Five minute average to generate warning\n";
	print "-c (--critical)  = Five minute average to generate critical alert ( w < c )\n";
	print "-l (--login)     = Login to use with SSH\n";
	print "-i (--identity)  = Identity file to use with SSH\n";
	print "-t (--timeout)   = Plugin timeout in seconds (default = $utils::TIMEOUT)\n";
	print "-h (--help)\n";
	print "-V (--version)\n";
	print "-v (--verbose)   = debugging output\n";
	print "\n\n";
	support();
}
