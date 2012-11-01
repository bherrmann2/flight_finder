#!/usr/bin/perl -w
#!perl -w

use File::Find; 
use File::Path; 
use File::Copy; 
use CGI;
# --- GLOBALS --- 
$VERSION = "1.0";

# Some test examples:
#1190142892:Tue Sep 18 19:14:52 2007
#1190056513:Mon Sep 17 19:15:13 2007
#1189970121:Sun Sep 16 19:15:21 2007
#1189883728:Sat Sep 15 19:15:28 2007
#1189797335:Fri Sep 14 19:15:35 2007

#Directories will be read into this "customers database
$customers = {};

#Print top level menu
$query = new CGI;

#what we are sending back
$html = "";
#Any error html
$error_html = "";
#Debug only
$debug_html = "";


#Set the following globals:
# $upload_dir $archive_dir $upload_uri $archive_uri
# $filename $type $customer_id $time $action
set_globals();

 

#
# First handle all the cases of this script that are NOT uploading an image
#
if (!$filename && !$type && !$customer_id && !$time)
{
  if ($action eq "test")
  {
    $html .= getTestInterface();
  }
  elsif ($action eq "getclient")
  {
   $html .= getPerlCode('send_image.pl');
  }
  elsif ($action eq "getcode")
  {
   $html .= getPerlCode('upload.cgi'); #FIXME - get it programatically
  }
  elsif ($action eq "deletedb")
  {
    if ($query->param("pass") eq "kerry4")
    {
      foreach ($upload_dir, $archive_dir)
      {
        rmtree($_); #Remove anything that was there.
        $html .= "Directory deleted: $_<br>";
      }
    }
    else
    {
      $html .= "Password is incorrect.";
    }
  }
  else 
  {
    $html .= getDisplayInterface();
  }
}

## If we got to this point, we are uploading an image.
#Defend against missing data for upload
#FIXME - Should really return non-200
elsif (!$filename || !$type || !$customer_id || !$time)
{
   $error_html .= "Some of the data is missing: filename=$filename type=$type cusomter_id=$customer_id time=$time";

}
else
{
  $filename =~ s/.*[\/\\](.*)/$1/;
  $error_html .= get_error_message_for_data();
  #bail out here if error.
  if ($error_html) {print_response(); exit;}
  
  $upload_filehandle = $query->upload("image");


  #e.g. 3it/latency/hour
  $relative_path = $customer_id . "/" . $type . "/" . $time;

  #e.g. 3it/latency/hour/58838111.png
  $relative_path_and_file = $relative_path . "/" . $filename;

  #e.g. ../uploads/3it/latency/hour
  $full_path = $upload_dir . "/" . $relative_path;

  #e.g. ../uploads/3it/latency/hour/58838111.png
  $full_path_and_file = $full_path . "/" . $filename; 

  #e.g. /uploads/3it/latency/hour/58838111.png
  $full_uri_to_file = $upload_uri . "/" . $relative_path_and_file;

  #Now make sure that all the directories we need exist.
  $path = $upload_dir . "/" . $customer_id;
  mkdir($path);
  $path = $path . "/" . $type;       
  mkdir($path);
  $path = $path . "/" . $time;            
  mkdir($path);
  #Tricky perl way to do this would be something like this:
  #$path = $upload_dir;
  #foreach ($customer_id,$type,$time){mkdir($path .= "/$_");}

  #print "relative_path=$relative_path<br>relative_path_and_file=$relative_path_and_file<br>full_path=$full_path<br>full_path_and_file=$full_path_and_file<br>full_uri_to_file=$full_uri_to_file<br>";
  #Clean out the directory, archive days' graph if needed.
  archive_if_needed($customer_id,$type,$time);

  #Delete everything, overwrite it (anything we need has been archived previously)
  clean_upload_dir($customer_id,$type,$time);





  $debug_html .= "<b>About to write this file:$full_path_and_file<br>";
  if( open (UPLOAD, ">$full_path_and_file")  )
  {
    binmode UPLOAD;
    while ( <$upload_filehandle> )
    {
	print UPLOAD;
    }
    close UPLOAD;
  }
  else
  {
     $error_html .= "<blink>Write failed for $full_path_and_file with error $!</blink>";
  }

  #Paranoid check
  if (!(-e $full_path_and_file))
  {
	$error_html .= "<BLINK>Write to this file failed: $full_path_and_file</blink>";
  }

  $html .= <<END_HTML;
<HTML> <HEAD> <TITLE>Thanks!</TITLE> </HEAD> <BODY>
<P>Your image:</P>
<img src="$full_uri_to_file" border="0">
</BODY> </HTML>

END_HTML
}

print_response();
exit;

#
# Nothing should be 'print'ed from the rest of the
# script.  the whole $html should be built up in the following
# global variables: $html, $error_html, $debug_html
# This is called at the very end.
sub print_response
{
   $header = ($error_html) ?
     $query->header(-type=>'text/html',-status=>'503 Data error' ) :
     $query->header();
   print $header;
   print "<font color=red><b>" . $error_html . "</b></font><hr>";
   print getMenuHtml() . "<hr>";
   print $html;
}
sub clean_upload_dir
{
	my ($customer_id, $type, $time) = @_;

	my $dir = "$upload_dir/$customer_id/$type/$time";
	rmtree ($dir);
	mkdir ($dir);
	if (!(-e $dir))
	{
		$error_html .= "<blink>CLEANDIR failed.</blink>";
	}
}
#
# This routine looks at graphs of the "day" type.  If a graph has not
# yet been archived for that day, it is copied off to the archive directy.
# The results should be that one day graph per day is archieved presumably 
# sometime around 00:01 am each day.
#
sub archive_if_needed #($customer_id,$type,$time)
{
  #get params
  my ($customer_id,$type,$time) = @_;                         
  return unless ($time eq "day");

  #make sure our archive directory is there
  my $archive_path = $archive_dir . "/" . $customer_id;
  mkdir($archive_path);
  $archive_path = $archive_path . "/" . $type;       
  mkdir($archive_path);

  #there should only be one file in here, but we will copy everything.
  #FIXME - We should really protect against this possible error.
  $day_dir = "$upload_dir/$customer_id/$type/$time";
  $day_dir_and_file = "";
  if (opendir(DIR, $day_dir))
  {
    while (defined($file = readdir(DIR))){$day_dir_and_file = "$day_dir/$file" unless !($file =~ /\d+\.png/);}
    closedir(DIR);
  }
  else
  {
    $error_html .= "<blink>CANT OPEN THIS DIR: $day_dir $!</blink><br>";
  }

  #Find out what day our current file is...
  if ($day_dir_and_file ne "")
  {
      $archive_day_path_and_filename = 
        $archive_path . "/" . get_archive_file_name($day_dir_and_file);
  }
  else
  {
    #FIXME - We should check that the directory only contains . and ..
    #if $day_dir_and_file turns up as "" and the directory has files, this is
    #an unexpected error case.
    return; #we assume that this is the very first day file uploaded.
  }

  #If we have already archived a file for this day, we dont need another...
  if (-e $archive_day_path_and_filename)
  {
	  return;
  }
  else
  {
    my $from = $day_dir_and_file;
    my $to = $archive_day_path_and_filename;
    $html .= "<b>...coping $from --to-- $to<br></b>";
    copy($from,$to);
    if (!(-e $to))
    {
	    $error_html .= "<blink>copy must have faild for $from to $to : $!</blink>";
    }
  }
}#archive_if_needed


sub get_archive_file_name #(time)
{
   my $file = shift;
   my $time = "";
   if ($file =~ /(\d+)\.png$/)
   {
	   $time = gmtime($1);
   }
   else
   {
	  $error_html .= "<blink>ERROR: This did not match file regex for time: $file</blink>";
   }
   if ($time =~ /^\w+\s+(\w+)\s+(\d+)\s+\d+:\d+:\d+\s+(\d+)/)
   {
     return $3 . "-" . $1 . "-" . $2 . ".png"; #2007-Sep-18.png
   }
   else
   {
	  $error_html .= "<blink>ERROR: This did not match gmtime regex: $time</blink>";
   }
}#getArchiveFileName


#
# read all the directories and generate the $customers data structure
#
sub generate_database
{
	find(\&wanted,$upload_dir);
}


#
# workhorse method for generate_database
#
sub wanted
{
  #What ends up in the list is something like:
  #3it/response/day/63631.png
  my $f = $File::Find::name;
  $f =~ s/^$upload_dir//;
  if (-f)
  {
    push(@graphs,$f);
    if ($f =~ /\/([^\/]+)\/([response|latency]+)\/([day|hour|week|06hr]+)\/(\d+)\.png$/)
    {
      #FIXME - This mess can be reduced to about 3 lines of code.
      $customers->{$1} = {} unless ($customers->{$1});
      if(($2 eq "latency")&&($3 eq "day"))
        {$customers->{$1}->{'latency/day'} = $f;}
      if(($2 eq "response")&&($3 eq "day"))
        {$customers->{$1}->{'response/day'}= $f;}
      if(($2 eq "latency")&&($3 eq "hour"))
        {$customers->{$1}->{'latency/hour'} = $f;}
      if(($2 eq "response")&&($3 eq "hour"))
        {$customers->{$1}->{'response/hour'} = $f;}
      if(($2 eq "latency")&&($3 eq "week"))
        {$customers->{$1}->{'latency/week'} = $f;}
      if(($2 eq "response")&&($3 eq "week"))
        {$customers->{$1}->{'response/week'} = $f;}
      if(($2 eq "latency")&&($3 eq "06hr"))
        {$customers->{$1}->{'latency/06hr'} = $f;}
      if(($2 eq "response")&&($3 eq "06hr"))
        {$customers->{$1}->{'response/06hr'} = $f;}
    }
    else
    {
      $error_html .= "<BLINK>ERROR: REGEX FAILED FOR FILE: <b>" . $f . "</b></BLINK>";
    }
  }#endif file
}

#
# Generates the actual HTML that we will use for each graph
sub getHtmlForGraph
{
  my ($customer_id, $graph) = @_;
  my $file = $customers->{$customer_id}->{$graph};
  my $timestamp = "";

  #If file is of the 1190055310.png format, the number is a utc time
  if ($file =~ /(\d+)\.png$/)
  {
    $timestamp = gmtime($1);
  }
  my $html = "";
  if ($customers->{$customer_id}->{$graph})
  {
    my $uri = $upload_uri . $file;
    $html .= "<img alt='" . $uri . "' src='" . $uri . "'>";
    #FIXME - add the date of the file ?
    $html .= "<br>$timestamp" unless (!$timestamp);
  }
  else
  {
    $html .= "Does not exist.";
  }
  return $html;
}
sub getMenuHtml
{
	return "<b>Main Menu:</b> <a href=?>Home</a> | <a href=?action=test>Test Interface</a> | <a href=mailto:werwath\@gmail.com?subject=HELP>Help</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>Time:</b>" . gmtime(time()) . "&nbsp;&nbsp;&nbsp;&nbsp;<b>Version:</b> " . $VERSION . "<hr>";

}
sub getDisplayInterface
{
  generate_database();
  my @customer_ids = sort keys(%$customers); 
  my $out  = "";
  $out  .= "<center><b>Customer/Data Centers: </b>";
  my $customer_Id = "";
  foreach $customer_id (sort keys(%$customers)  )
  {
    $out  .= "<a href='#" . $customer_id . "'>" . $customer_id . "</a> | ";
  }
  $out  .= "</center><hr>";
  foreach $customer_id (sort keys(%$customers))
  {
    $out  .= "<a name='" . $customer_id . "'><h2>" . $customer_id . "</h2></a>\n";
    $out  .= "<table border>\n";
    $out  .= "<tr><td><td><b>latency</b><td><b>response</b>\n";
    $out  .= "<tr><td><b>hour</b><td>" . 
      getHtmlForGraph($customer_id,'latency/hour') . "<td>" . 
      getHtmlForGraph($customer_id,'response/hour') . "\n";
    $out  .= "<tr><td><b>06hr</b><td>" . 
      getHtmlForGraph($customer_id,'latency/06hr') . "<td>" . 
      getHtmlForGraph($customer_id,'response/06hr') . "\n";
    $out  .= "<tr><td><b>day</b><td>" . 
      getHtmlForGraph($customer_id,'latency/day') . "<td>" . 
      getHtmlForGraph($customer_id,'response/day') . "\n";
    $out  .= "<tr><td><b>week</b><td>" . 
      getHtmlForGraph($customer_id,'latency/week') . "<td>" . 
      getHtmlForGraph($customer_id,'response/week') . "\n";

    $out  .= "</table>";

  }#foreach
  $out = <<END_IF;
<HTML>
 <HEAD><meta http-equiv="refresh" content="60" ></HEAD>
 <BODY>
 $out 
 </BODY>
</HTML>
END_IF

  return $out;
}


#
# Prints out perl code in a format suitable for displaying on an html page
# assumes the file is in the same directory as this script
#
sub getPerlCode #($file)
{
  my $file = shift;
  #print "Save the following file to send_image.pl:<hr><pre>";
  open(F,$file) || die "Could not open $file";
  my $lines = join('',(<F>));
  close F;
  $lines =~ s/</&lt;/g;
  $lines =~ s/>/&gt;/g;
  return   "<pre>$lines</pre>";
}
sub getTestInterface
{
my $out = <<TEST;   
<HTML>
 <HEAD></HEAD>
 <BODY>
 <FORM METHOD="post" ENCTYPE="multipart/form-data">
 Image: <INPUT TYPE="file" NAME="image"><br>
 Customer Id: <INPUT NAME="customer_id" value=3it><br>
 Type: <select name=type><option>latency<option>response</select><br>
 Time: <select name=time><option>hour<option>06hr<option selected>day<option>week</select><br>
 <INPUT TYPE="submit" NAME="Submit" VALUE="Submit PNG">
 </FORM>
 <p>
 <p>
 <h3>Useful Links:</h3>
 <li><a href=?action=getclient>Get perl client to upload images</a>
 <li><a href=?action=getcode>Get perl code for this script</a>
 <li><a href="$upload_uri">View existing uploads</a>
 <li><a href="$archive_uri">View existing archives</a>
 <h3>Bring the Pain:</h3>
 <form><input type=submit value='Clobber Whole DATABASE'>Password:<input name=pass type=password><br><input type=hidden name=action value=deletedb></form>
 </BODY>
</HTML>
TEST

  return $out;
}

sub set_globals                                          
{
#Create our database directory if it does not exist.
if (-e "../htdocs")
{
  $upload_dir = "../htdocs/uploads";
  $archive_dir = "../htdocs/archived_uploads";
}
else
{
  $upload_dir =  "../uploads";
  $archive_dir = "../archived_uploads";
}
$upload_uri = "/uploads";
$archive_uri = "/archived_uploads";
mkdir($upload_dir) unless -e $upload_dir;
mkdir($archive_dir) unless -e $archive_dir;

# Get all of the query data
#The image file 
$filename = $query->param("image");

#latency or response
$type = $query->param("type");

#customer id (unique)
$customer_id = $query->param("customer_id");

#time (day or hour)               
$time = $query->param("time");
 
#action (test)                    
$action = $query->param("action");
} #make_sure_all_needed_directories_exist


#FIXME - Check the data !!! make sure it is correct and non-destructive !!!
# - no whitespace
# - type is "latency" or "response"
# - time is 06hr, hour, day, or week 
# Note: set_globals must be called before calling this.
sub get_error_message_for_data()
{
  my $msg = "";
  $msg .= "file '$filename' is not correct format. " unless ($filename =~/^\d+\.png$/);
  $msg .= "type '$type' is not 'latency' or 'response'. " unless ($type eq "latency" || $type eq "response");
  $msg .= "time '$time' is not hour|06hr|day|year." unless ($time =~ /^[hour|06hr|day|week]+$/);
  $msg .= "customer_id '$customer_id' contains whitespace."  unless ($customer_id =~ /^\S+$/);
  return $msg;


}
