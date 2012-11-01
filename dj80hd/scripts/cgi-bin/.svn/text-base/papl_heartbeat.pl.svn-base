#!/usr/bin/perl 
use CGI;
$q = new CGI;
$NAGIOS_ERROR_EXIT = 2;
$NAGIOS_WARNING_EXIT = 1;
$NAGIOS_SUCCESS_EXIT = 0;
$PAPL_TIMEOUT_SECS = 60 * 20; # 20 minutes.
$PAPL_HEARTBEAT_DB = "papl_heartbeat.txt";
$CONTENT_TYPE = "Content-type: text/html\n\n";
$BACKDOOR_PASSWORD = "kerry4";
$ACCEPTED_IP = "199.177.12.5";

sub is_authorized {
  return (($ENV{'REMOTE_ADDR'} == $ACCEPTED_IP) || ($BACKDOOR_PASSWORD == $q->param('pass')))
}#is_authorized

sub get_file_contents { #($filename)
  my $fname = shift;
  open(F,$fname) || die "Could not open $fname";
  my $text = <F>;
  close F;
  return $text;
}
sub secs_since_last_papl_heartbeat {
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($PAPL_HEARTBEAT_DB);  
  return (time() - $mtime);
}#secs_since_last_papl_heartbeat


sub set_file_contents { #($filename,$contents)
  my ($fname,$contents) = @_;
  open(F,">$fname") || die "Could not open $fname";
  print F $contents;
  close F;
}

# returns 2 if aca is known to be in error state
# returns 0 if aca is known to be in ok state
# returns 1 otherwise
sub nagios_code_for_aca { #(aca)
  my $aca = shift;
  my $contents = get_file_contents($PAPL_HEARTBEAT_DB);
  my $index_ok = index($contents,$aca . "=1");
  if ($index_ok >= 0) {
    return $NAGIOS_SUCCESS_EXIT;
  } 
  else {
    if (index($contents,$aca . "=0") >= 0 ) {
      return $NAGIOS_ERROR_EXIT;
    }
    else {
      return $NAGIOS_WARNING_EXIT;
    }
  }
}#nagios_code_for_aca

sub get_test_interface() {
  my $test_interface = "<form>";
  $test_interface .= "x1:<select name=x1.novarra.com><option>0<option>1</select>";
  $test_interface .= "x2:<select name=x2.novarra.com><option>0<option>1</select>";
  $test_interface .= "x3:<select name=x3.novarra.com><option>0<option>1</select>";
  $test_interface .= "<input type=submit value=Update></form>";
  $test_interface .= "<form><input name=action value=show type=submit></form>";
  $test_interface .= "<hr><form><select name=aca><option>x1.novarra.com<option>x2.novarra.com<option>x3.novarra.com</select><input type=hidden name=action value=check_aca><input type=submit value=Check></form>\n";
  return $test_interface;        
}
#
#
#
#
sub create_db_file_if_needed {
  if (!(-e $PAPL_HEARTBEAT_DB)) {
    open(F,">$PAPL_HEARTBEAT_DB") || die "Could not create file $PAPL_HEARTBEAT_DB";
    print F " ";
    close F;
  }
  chmod 0777, $PAPL_HEARTBEAT_DB;
}#create_db_file_if_needed



#This really only does anything the very first time it is run.
create_db_file_if_needed();

#If this is being called from the command line...
#So we treat this like a normal nagios plugin
if ($#ARGV >= 0) {
  $what_to_check = $ARGV[0];
  if ($what_to_check eq "papl") {
    $secs = secs_since_last_papl_heartbeat();
    if ($secs > $PAPL_TIMEOUT_SECS) {
      print "PAPL has not heartbeat for $secs seconds";
      return $NAGIOS_ERROR_EXIT;
    }
    else {
      print "PAPL heartbeat $secs seconds ago.";
      return $NAGIOS_SUCCESS_EXIT;
    }
  }
  #if what_to_check is not 'papl' we assume it is the name of an aca.
  else {
    my $code = nagios_code_for_aca($what_to_check);
    print "ACA $what_to_check STATUS = $code";
    exit $code;
  }
}
#Otherwise assume this is being called from CGI/Internet
else {
  print $CONTENT_TYPE;
  @param_names = $q->param;
  
  #If we got parameters, write them to the file
  if (@param_names && $#param_names >= 0) {
    my $action = $q->param('action');
    #Web query is to show database
    if ($action eq "show") {
      print "DB: <pre>" . get_file_contents($PAPL_HEARTBEAT_DB) . "</pre>";
    }
    elsif ($action eq "check_aca") {
       my $aca = $q->param('aca');
       my $code = nagios_code_for_aca($aca);
       print "CODE for ACA $aca is $code";
    }
    else {
      my $contents = "";
      foreach (@param_names) {
        $contents = $contents . $_ . "=" . $q->param($_) . "&";
      }
      #FIXME - Check contents before writing ?
      set_file_contents($PAPL_HEARTBEAT_DB,$contents);
      #FIXME - Check that what we wrote is there ?
      print "OK";
    }
    exit;
  }
  #Otherwise print the test interface.
  else {
    print get_test_interface();
    exit;
  }
}
