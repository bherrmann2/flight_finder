#! /usr/local/groundwork/bin/perl -w
#
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
use vars qw($host $opt_V $opt_h $opt_v $opt_l $opt_i $verbose $PROGNAME $opt_w $opt_e $opt_c $opt_t $opt_H $status $state $msg $msg_q $MAILQ $SHELL $device $dev $swaplo $blocks $free $percent $CMD $RMTOS);
use lib  "/usr/lib/nagios/plugins" ;
use utils qw(%ERRORS &print_revision &support &usage );

sub print_help ();
sub print_usage ();
sub process_arguments ();

$ENV{'PATH'}='';
$ENV{'BASH_ENV'}=''; 
$ENV{'ENV'}='';
$PROGNAME = "check_swap_remote";

Getopt::Long::Configure('bundling');
$status = process_arguments();

if ($status){
	print "ERROR: processing arguments\n";
	exit $ERRORS{"UNKNOWN"};
}

$SIG{'ALRM'} = sub {
	print ("ERROR: timed out waiting for $CMD on $host\n");
	exit $ERRORS{"WARNING"};
};

$host = $opt_H;

alarm($opt_t);

$CMD="uname";
my $RMTOS = `$SHELL $host $CMD 2>/dev/null`;
chomp($RMTOS);

if ( $RMTOS eq "HP-UX" ) {
	$CMD = "/usr/sbin/swap -l";
} elsif ( $RMTOS eq "SunOS" ) {
	$CMD = "/usr/sbin/swap -l"; 
} else {
	$CMD = "/usr/sbin/swap -l"; 
}

alarm($opt_t);

## get cmd output from remote system

if (! open (OUTPUT, "$SHELL $host $CMD 2>/dev/null| " ) ) {
	print "ERROR: could not open $CMD on $host\n";
	exit $ERRORS{'UNKNOWN'};
}

my $perfdata = "";
my $state = "-1";

while (<OUTPUT>) {
	print $_ if $verbose;
	if (/^\/dev/) {
		my ($device, $dev, $swaplo, $blocks, $free) = split;
		if ($blocks gt 0 ) {
		  $percent=($blocks-$free)/$blocks;
		} else {
		  $percent=0;
		}
		$perfdata = $perfdata . "$device=$percent;;;0;100 ";

		my $val=$percent;

			print "percent = $percent warn=$opt_w crit=$opt_c\n" if $verbose;

			if ($val < $opt_w) {
				if ( $state <= $ERRORS{'OK'} ) {
					$state = $ERRORS{'OK'};
					$msg = "OK: All Swap devices are below threshold ($opt_w/$opt_c\%)";
				}
			} elsif ($val >= $opt_w  && $val < $opt_c) {
                                if ( $state <= $ERRORS{'WARNING'} ) {
					$state = $ERRORS{'WARNING'};
					$msg = "WARNING: $device is $percent (threshold w = $opt_w\%)";
				}
			} else {
                                if ( $state <= $ERRORS{'CRITICAL'} ) {
					$state = $ERRORS{'CRITICAL'};
					$msg = "CRITICAL: $device is $percent (threshold c = $opt_c\%)";
				}
			}
	}
}

close (OUTPUT); 
# declare an error if we also get a non-zero return code
# unless already set to critical
if ( $? ) {
	print "stderr = $? : $! \n" if $verbose;
	$state = $state == $ERRORS{"CRITICAL"} ? $ERRORS{"CRITICAL"} : $ERRORS{"UNKNOWN"}  ;
	print "error: $!\n" if $verbose;
}
## close cmd

# Perfdata support
print "$msg | $perfdata\n";
exit $state;


#####################################
#### subs


sub process_arguments(){
	GetOptions
		("V"   => \$opt_V, "version"	=> \$opt_V,
		 "v"   => \$opt_v, "verbose"	=> \$opt_v,
		 "h"   => \$opt_h, "help"	=> \$opt_h,
		 "e=s" => \$opt_e, "shell=s"	=> \$opt_e,
		 "l=s" => \$opt_l, "login=s"	=> \$opt_l,
		 "i=s" => \$opt_i, "identity=s"	=> \$opt_i,
		 "w=f" => \$opt_w, "warning=f"  => \$opt_w,   # warning if above this number
		 "c=f" => \$opt_c, "critical=f" => \$opt_c,   # critical if above this number
		 "t=i" => \$opt_t, "timeout=i"  => \$opt_t,
	         "H=s" => \$opt_H, "hostname=s" => \$opt_H
		 );

	if ($opt_V) {
		print_revision($PROGNAME,'$Revision: 1.0 $ ');
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
	print "Usage: $PROGNAME -e <shell> -H <hostname> [-w <warn>] [-c <crit>] [-t <timeout>] [-v verbose] [-l <login>] [-i <identity>]\n";
}

sub print_help () {
	print_revision($PROGNAME,'$Revision: 1.1 $');
	print "Copyright (c) 2004 jeff scott\n";
	print "\n";
	print_usage();
	print "\n";
	print "   Checks the Swap Usage on remote system over SSH or RSH\n";
	print "-e (--shell)     = ssh or rsh (required)\n";
	print "-H (--hostname)  = remote server name (required)\n";
	print "-w (--warning)   = Percent Used to generate warning alert\n";
	print "-c (--critical)  = Percent Used to generate critical alert ( w < c )\n";
	print "-l (--login)     = Username for ssh login\n";
	print "-i (--identity)  = Identity file for ssh login\n";
	print "-t (--timeout)   = Plugin timeout in seconds (default = $utils::TIMEOUT)\n";
	print "-h (--help)\n";
	print "-V (--version)\n";
	print "-v (--verbose)   = debugging output\n";
	print "\n\n";
	support();
}
