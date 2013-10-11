#!/usr/local/groundwork/bin/perl -w
#
# Log file regular expression detector for Nagios.
# Written by Serge Sergeev (serge at ocslab.com)
# Based on check_log2.pl written by Aaron Bostick (abostick@mydoconline.com)
# Last modified: 06-07-2005
#
# Usage: check_logs -c <configuration_file> 
# For usage detiles: check_logs --help 
#
# Description:
# This plugin will scan arbitrary text files looking for regular expression 
# matches.  
BEGIN {
    if ($0 =~ s/^(.*?)[\/\\]([^\/\\]+)$//) {
        $prog_dir = $1;
        $prog_name = $2;
 	unshift(@INC,$prog_dir);
    }
}
require 5.004;
use vars qw($opt_c $opt_v $opt_h $opt_l $opt_s $opt_p $opt_n $prog_dir $prog_name);
use utils qw($TIMEOUT %ERRORS &print_revision &support &usage);
use Getopt::Long;
use strict;

sub print_usage ();
sub print_version ();
sub print_help ();

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
my $conf_file = '';
my %res;
my $plugin_revision = '$Revision: 1.1 $ ';
our $seek_file_template;
our @log_files;

print_help() if ! GetOptions ( 
	"l|logfile=s"      => \$opt_l,
	"s|seekfile=s"     => \$opt_s,
	"p|pattern=s"      => \$opt_p,
	"n|negpattern:s"   => \$opt_n,
	"c|conf=s"         => \$opt_c,
	"v|version"        => \$opt_v,
	"h|help"           => \$opt_h 
);

($opt_v) && print_version ();
($opt_h) && print_help ();
usage("Other options not allowed if -c <configuration file> is used\n") if ( $opt_c && ($opt_l || $opt_s || $opt_p || $opt_n ));
usage("Specify at least -l <log_file> -s <seek_file>  -p <pattern> options if you don't use -c <configuration file>\n") if ( !( ($opt_l && $opt_s && $opt_p ) || $opt_c ) );
if ( $opt_c ) {
	eval('require "' . $opt_c . '"') or usage("Error: can not load configuration file.\n");} else {
	@log_files = (	{ 
		'file_name'		=> $opt_l,
		'reg_exp'			=> $opt_p,
		'neg_reg_exp'	=> $opt_n,
	}	);
	$seek_file_template = $opt_s;
}	
########################## main_loop ############################
foreach my $cnf ( @log_files ) {
    my @seek_pos;
    $cnf->{'file_name'} =~ m/^(.*?)[\/\\]([^\/\\]+)$/;
    my $fbasename = $2;
    my $seek_file = $seek_file_template;
    $seek_file =~ s/\$log_file/$fbasename/;
    $seek_file .= $cnf->{'seek_file_suffix'} if defined($cnf->{'seek_file_suffix'});
    next unless ( -r $cnf->{'file_name'} );
    # Open log file
    open LOG_FILE, $cnf->{'file_name'} || die "Unable to open log file $cnf->{'file_name'}: $!";
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
    # Loop through every line of log file and check for pattern matches.
    # Count the number of pattern matches and remember the full line of 
    # the most recent match.
    my $lc = 0;
    my $add_lines = '';
    my $pattern_line = '';
    my $pattern_count = 0;
	  $cnf->{'lines'} = 1 if  ! defined( $cnf->{'lines'} );
    while (<LOG_FILE>) {
			chomp ;
			s/\x0d//m;
			if ($lc !=0 && $lc < $cnf->{'lines'} ){
				if ( $cnf->{'new_line_reg_exp'} ) {
					if ( $_ !~ $cnf->{'new_line_reg_exp'} ) {
						$add_lines = $lc==1?$_:$add_lines . $_ ;
            $lc++; 
					} else {
						$lc = $cnf->{'lines'};
					}
				} else { 	
        	$add_lines = $lc==1?$_:$add_lines . $_ ;
					$lc++; 
				}
			}
 			if ($cnf->{'neg_reg_exp'}) {
				if ((/$cnf->{'reg_exp'}/) && !(/$cnf->{'neg_reg_exp'}/)) {
					$pattern_count += 1;
					$pattern_line = $_;
				}
			} elsif (/$cnf->{'reg_exp'}/) {
 				$pattern_count += 1;
				$pattern_line = $_;
				$lc=1;
			}
    }
    # Overwrite log seek file and print the byte position we have seeked to.
    open(SEEK_FILE, "> $seek_file") || die "Unable to open seek count file $seek_file: $!";
    print SEEK_FILE tell(LOG_FILE);
    close(SEEK_FILE);
    close(LOG_FILE);
    $res{$fbasename}->{'message'} = $pattern_line . $add_lines;
    $res{$fbasename}->{'count'} = $pattern_count;
}
my $exit_code = $ERRORS{'OK'};
foreach my $i ( sort keys %res ) {
  if ( $res{$i}->{'count'} ) {
   print "$i => ($res{$i}->{'count'}): $res{$i}->{'message'}; ";
   $exit_code = $ERRORS{'WARNING'}; }
  else {
   print "$i => OK; ";
  }
}
print "\n";
exit $exit_code;
#
sub print_usage () {
    print "Usage: $prog_name ( -c <configuration file> | -l <log_file> -s <log_seek_file> -p <pattern> [-n <negpattern>] )\n";
    print "Usage: $prog_name [ -v | --version ]\n";
    print "Usage: $prog_name [ -h | --help ]\n";
}
sub print_version () {
    print_revision($prog_name, $plugin_revision);
    exit $ERRORS{'OK'};
}
sub print_help () {
    print_revision($prog_name, $plugin_revision);
    print "\n";
    print "Scan arbitrary n log files for regular expression matches.\n";
    print "\n";
    print_usage();
    print "\n";
    print "-c, --conf=<confile>\n";
    print "    The configuration file(see syntax below)\n";
    print "-l, --logfile=<logfile>\n";
    print "    The log file to be scanned\n";
    print "-s, --seekfile=<seekfile>\n";
    print "    The temporary file to store the seek position of the last scan\n";
    print "-p, --pattern=<pattern>\n";
    print "    The regular expression to scan for in the log file\n";
    print "-n, --negpattern=<negpattern>\n";
    print "    The regular expression to skip in the log file\n";
    print "The configuration file syntax\n";
    print <<EOC;
# Required file name template to store position of the end of file last check
\$seek_file_template='/var/lib/nagios/\$log_file.check_log.seek';

# Required log files array
\@log_files = ( 
   {'file_name' => '/var/log/messages',    #required file name
    'reg_exp' =>'check pass; user unknown',#required reg_exp
    'lines' => 2, 			   #optional number of output lines  after match
#    'new_line_reg_exp' => '^',		   #optional new line regex to stop output lines
     'seek_file_suffix' => '2' 	   	   #optional seek file suffix
   },
   {'file_name' => '/var/log/secure',    #required file name
    'reg_exp' =>'Failed password for',	  #required reg_exp
   },
);
EOC
    print "\n";
    support();
    exit $ERRORS{'OK'};
}
