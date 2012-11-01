<?php
include('spyc.php');
//Display all errors
error_reporting(E_ALL);
ini_set("display_errors", 1);
//
//  History
//  -------------------------------------------------------------------
//  Date        name         comment
//  ----------- --------     ------------------------------------------
//  14-SEP-2008 jwerwath     Really get next from database, not file
//  14-SEP-2008 jwerwath     Support count parameter                   
//  23-SEP-2008 jwerwath     Several Major updates including IP Checking, 
//                           Configruation file, etc.
//  29-SEP-2008 jwerwath     Add marks IP.
//  02-OCT-2008 jwerwath     Updates to config
//  05-NOV-2008 jwerwath     Add 90.152.20.18
//  01-DEC-2008 jwerwath     Add 213.161.85.100  (3it reports server)
//  05-DEC-2008 jwerwath     Allow deleting of database by code (customer)
//  08-DEC-2008 jwerwath     Fix the voyeur feature to pull real data     
// 
//  A. HTTP Interfaces
//  ===============================================================
//  1. Getting the next URL to load
//     FORMAT: ?action=get_next&type=<type>&count=count
//     where <type> is aardvark or j2me or brew or ie
//       ?action=get_next&type=aardvark&count=4
//
//  2. Adding url/ua data to the system.
//     FORMAT: HTTP post with the following parameters...
//     code = (3it | 3hk | vfuk | turkcell ... etc.)
//     action = add_data
//     data = A newline seperated lists of url-ua pairs where the url-ua
//            is seperated by a | (See B. Example data section)
//
//  3. Updating the configuration on the fly (only for unit testing) 
//
//  4. Getting the mobile interface to load a URL and have it pushed out to all the systems
//  5. Getting the backdoor admin interface
//
//  6. Getting the ie (desktop) voyeur interface
//   
//  7. Getting the mobile voyeur interface
//
//  8. Getting the mobile portal to load a page and have it appear on all
//     the monitors.
//
//  B. Example data 
//     ...
//     http://mycounter.tinycounter.com|BlackBerry7130e/4.1.0
//     http://88.214.227.83|Nokia6133/2.0 (05.60) Profile/MIDP-2.0 CLDC-1.1
//     ...
//  
//
//  --------------------------------------------
//  next
// 
// 
// TODO - 
// - Prevent Dups
// - Check for all mysql errors ?
// - May need multiple entries, 1 for each type when adding a user request so
//   each device/client is sure to grab it.
// - reuse database connections
// - If database is empty return novarra.com
//
//
// 
//
// ERROR CODES:
// 601 - Invalid data format to be added.
// 602 - Invalid IP (IP is not allowed to access The system)
//
//Default ACA through which pages should be loaded.
//This gets overridden by the config file

//FIXME - read this from a config file
$CUSTOMER_CODES = array('turkcell','3it','3hk','yahoo','usc','wind','tim','vfuk','user','all');

//When we have to punt, the system will grab a random URL from this file
//each line is formated like <url>|<ua> 
//e.g.
//http://www.haberler.com|Nokia6085/2.0 (03.71) Profile/MIDP-2.0 Configuration/CLDC-1.1
//
$TEST_FILE = 'ulog_url_ua.txt';
$CONFIG_FILE = 'config.yml';
$config_yaml = Spyc::YAMLLoad($CONFIG_FILE);
$TEST_ACA = $config_yaml['aca'];

//this is the customer code used in the database when a user has made a request on the system
$USER_REQUEST_CODE = 'user';

//When testing, do not use the real database.
$TABLENAME = (strstr($_SERVER["SCRIPT_URL"],'ae_test')) ? 'url_ua_test' : 'url_ua';

//Standard set of columns requested for most queries
$COLUMNS = "id,url,ua,code,created_epoch_secs";

//HTML for a bunch of test links.
$TEST_LINKS_HTML = "<hr><b>Test Interfaces</b><br><form><input type=\"hidden\" name=\"action\" value=\"get_next\" /><input type=\"hidden\" name=\"type\" value=\"aardvark\" /><select name=\"cust\"><option>" . join("<option>",$CUSTOMER_CODES) . "</select>Count:<input size=\"3\" name=\"count\" value=\"1\" /><input type=\"submit\" value=\"Text Aardvark Extreme XML Interface\" /></form><br><a target=\"blank\" href=\"?action=admin\">Backdoor Admin Interface</a><br><a target=\"_blank\" href=\"ie_monitor.html\">Monitor (see what people are browsing...)</a><br/><a href=\"m.htm\">Mobile Interface</a>\n";

//SQL to create the table
$CREATE_TABLE_SQL = "create table " . $TABLENAME . " (id int NOT NULL AUTO_INCREMENT, url varchar(1024), ua varchar(1024), code varchar(64), created_epoch_secs int default 0, primary key (id))";

//SQL to create the table
$DROP_TABLE_SQL = "drop table if exists " . $TABLENAME;

//SQL to get the whole table
$SHOW_TABLE_SQL = "select * from " . $TABLENAME . " order by created_epoch_secs,code DESC";

//This application is only available to certain IP addresses.
$approved_ips = array(
        '199.177.12.5',  #Novarra
        '213.161.85.100', #3it report server
        '67.167.52.153', #Jim          
        '82.28.42.81', #Mark
        '90.152.20.18', #Mark2
        '24.13.214.226', #jim2
        '85.90.235.45', #vfuk reports server
        '12.130.107.105' #Novarra Web Tools Server @ATT
        );

//Info to make the database connection
$dbuser = "dj80hd_test"   ;
$dbpass = "dj80hd_test"   ;
$dbname = "dj80hd_test"   ;
$dbhost = (strstr($_SERVER['SERVER_NAME'],'scissorsoft.com')) ? 'mysql.djadhd.com' : '127.0.0.1' ;

//
// Append data to file
//
function append_data_to_file($filename,$data) {
  $fh = fopen($filename, 'a') or die("can't open file " . $filename);
  fwrite($fh, $data);
  fclose($fh);
}


//
//Send an HTTP error to the client
//
function http_error($number,$msg) {
  header("HTTP/1.1 " . $number . " " . $msg);
  print ("AE_ERROR:" . $msg);
  exit;
}


//
//Gets a querystring parameter by the given name, returns NULL if none.
//Any parameter returned will be mysql_escaped.
//
function param($name) {
  return (isset($_REQUEST[$name])) ? mysql_escape_string($_REQUEST[$name]) : NULL ;
}


//
// Returns the contents of an entire file as a string.
//
function get_file_as_string ($filename) {
  $output="";
  $f = fopen($filename, "r");
  while(!feof($f)) {
    $output = $output . fgets($f, 4096);
 
  }
  fclose ($f); 
  return $output;        
}//get_file_as_string


//
//Debug utility to mark info FIXME - Change this to log
//
function info($s) {
  print "<font color=red>" . $s . "</font>";
}

//
//Perform a mysql query and return the result.
//
function db_query($q) {
  global $dbh,$dbhost,$dbuser,$dbpass,$dbname;
  $dbh = mysql_connect ($dbhost,$dbuser,$dbpass) or die ('I cannot connect to the database because: ' . mysql_error() . "dbhost=" . $dbhost . " dbuser=" . $dbuser . " dbpass=" . $dbpass . " dbname=" . $dbname . " server=" . $_SERVER['SERVER_NAME']);
  //info("<br><b>QUERY is:</b> " . $q);
  mysql_select_db ($dbname) or die ('I could not select dbname ' . $dbname . ' because ' . mysql_error()); 
  $result = mysql_query($q,$dbh);
  if (!$result) {
    //info("ERROR: " . mysql_error());
  }
  return $result;
}


//
//Delete entires for a given code
//
function delete_entries_for_code($code) {
  global $TABLENAME;
  $code = mysql_escape_string($code);
  $q = "delete from " . $TABLENAME . " where code = '" . $code . "'";
  #FIXME - Check error ?
  $result = db_query($q);
}

//
//Delete an entry from the DB
//
function delete_entry($id) {
  global $TABLENAME;
  $id = mysql_escape_string($id);
  $q = "delete from " . $TABLENAME . " where id = " . $id;
  #FIXME - Check error ?
  $result = db_query($q);
}

//
//Delete an array of entries fom the database.
//
function delete_entries($entries) {
  //FIXME - Do this more efficiently by using a single SQL connection.
  if ($entries == NULL) return;
  foreach ($entries as $e) {
    delete_entry($e['id']);   
  }
}

//
//Get only the first row of a query.
//
function get_first_row($q) {
  $result = db_query($q);
  if ($result) {
    return mysql_fetch_row($result);
  }
  return NULL;
}

//
//Returns an SQL query that will return all the rows for a given customer
//If no customer is provided, ALL entries will be returned.
//
function get_select_query($cust = 'any') {
  global $TABLENAME, $COLUMNS;
  $q = "select " . $COLUMNS . " from " . $TABLENAME;
  if ($cust != NULL && $cust != 'any') {
    $q .= " where code='" . mysql_escape_string($cust) . "'";
  }
  $q .= " order by created_epoch_secs desc";
  return $q; 
}


function get_database_summary_as_html() {
  global $TABLENAME;
  $q = "SELECT code, COUNT(*) FROM " . $TABLENAME . " GROUP BY code";
  $result = db_query($q);
  $out = "<table border=1><tr><th>CUSTOMER CODE</th><th>COUNT</th></tr>\n";
  while ($myrow = mysql_fetch_row($result)) {
    $out .= "<tr><td>" . $myrow[0] . "</td><td>" . $myrow[1] . "</td></tr>\n";
  }
  $out .= "</table>\n";
  return $out;
}
//
//Returns the whole DB as HTML formatted tables.
//
function get_database_as_html() {
  $result = db_query(get_select_query());
  $out = "";
  if ($result) {  
    $out .= "<table border=1><tr><th>id<th>url<th>ua<th>code<th>created\n";
    while ($myrow = mysql_fetch_row($result)) {
      $out .= "<tr><td>" . $myrow[0] . "<td>" . "<a href=\"" . $myrow[1] . "\">" . $myrow[1] . "</a>" . "<td>" . $myrow[2] . "<td>" . $myrow[3] . "<td>" . date('r',intval($myrow[4]));
      $out .= "</tr>\n";
    }//end while
    $out .= "</table>\n";
  }
  return $out; 
}


//
//Turns a row form the DB into an array representing it
//
function row_to_entry($r) {
  if ($r) {
    #FIXME - this depends on the order
    return array("id" => $r[0], "url" => $r[1], "ua" => $r[2], "code" => $r[3], "created_epoch_secs" => $r[4]);
  }
  else {
    return NULL;
  }          
}


// 
// Returns random int between 0 and $max, including 0 but not including $max
// 
function random_int($max = 1) {
  $m = 1000000;                    
  return ((mt_rand(1,$m * $max)-1)/$m);
}

// 
// Gets a random line from a file without reading the whole file into memory.
// 
function get_random_line_from_file($filename) {
  $line_number = 0;                              
  $line = NULL;                                    
  $fh = fopen($filename,'r') or die ($php_errormsg);
  while (! feof($fh)) {
    if ($s = fgets($fh,1048576)) {
      $line_number++;             
      if (random_int($line_number) < 1) {
        $line = $s;
      }
    }
  }//endwhile
  fclose($fh) or die ($php_errormsg);  
  return $line;
}//get_random_line_from_file

#Assumes a file in the format of newline seperated
#url|ua pairs where url and ur are seperated by a 
#pipe character
function get_random_entry_from_file($filename) {
  $line = get_random_line_from_file($filename);
  if ($line) {
    list($url,$ua) = split('\|',$line);
    return array("id" => 0, "url" => $url, "ua" => $ua, "code" => "any", "created_epoch_secs" => 0);
  }
  else {
    return NULL;
  }
}

//
// Prints an http response with body $content
// and Content-Type header set to $content_type
//
function output($content, $content_type = 'text/html') {
  header("Content-Type: " . $content_type);
  print $content;
}


//
// If no actions are request print the default interface.
//
function print_default_page() {
  global $TEST_LINKS_HTML;
  $out = "<html><body>\n";
  $out .= $TEST_LINKS_HTML;
  $out .= "</body></html>";
  output($out);
}//print_default_page

function get_random_row() {
  global $COLUMNS;
  global $TABLENAME;
  $q = "select " . $COLUMNS . " from " . $TABLENAME . " order by rand() limit 1";
  $r = get_first_row($q);
  return $r;
}

//
// This is sent for ?action=get_next&type=ie and is meant to show a the contents of the URL that is
// being viewed by the user.  It pics a random url and sends it back.  This url is loaded from the 
// ie_monitor.html javascript applicaiton.
//
function send_ie_voyeur_response() {
  global $TEST_FILE;
  //Redirect to a script that will grab the url and proxy the page to
  //FIXME - get it from the DB 
  $r = get_random_row();
  $e = NULL;                    
  if (!($r)) {
    $e = get_random_entry_from_file($TEST_FILE);
  } 
  else {
    $e = row_to_entry($r);
  }
  if (!($e)) {
    http_error(605,"Could not get random entry");
    return;
  }
  $ua = $e['ua'];
  $url = $e['url'];
  $host  = $_SERVER['HTTP_HOST'];
  $uri   = rtrim(dirname($_SERVER['PHP_SELF']), '/\\');
  $extra = 'make_absolute.php?base=';
  header("Location: http://$host$uri/$extra" . urlencode($url));
  header('X-Novarra-User-Agent: ' . $ua);
}
// 
// Sends an HTTP response for the specified client type containing the 
// next URL(s) to load.
//
// Parameters
// ----------
// type - (aardvark | ie | j2me | brew) the type of client requesting the urls
// cust_code - (turkcell | 3hk | 3it | eetg ... etc) the customer from which we
//           should try to pull the urls
// count - the number of urls requested from the client
// 
function get_next($type, $cust_code = 'any', $count = 1) {
  global $TEST_FILE;
  if($type == 'aardvark') {
    $entries = get_latest_entries($cust_code, $count);
    if ($entries != NULL) {
      output(format_xml_response_for_aardvark($entries),'text/xml');
      delete_entries($entries);
    }
    #If there are no entries - keep rolling with some canned ones.
    else {
      $entry = get_random_entry_from_file($TEST_FILE);
      $entries = array($entry);
      output(format_xml_response_for_aardvark($entries),'text/xml');
    }
  }                          
  elseif($type == 'j2me') {
    //FIXME - we may want to use a simpler format for clients so they
    //Dont have to parse XML
  }                          
  else {
          send_ie_voyeur_response();
  }                          
}//get_next

function password_field_as_html() {
  return "<input type=text name=secret value='Enter secret word here'>";
}
function customer_selectlist_as_html() {
  global $CUSTOMER_CODES;
  return "<select name=\"code\"><option>" . join('<option>',$CUSTOMER_CODES) . "</select>";
}

function print_admin_interface() {
  global $TEST_FILE;
  $out = "<form method='post'>\n";
  $out .= "<h2>Backdoor Admin Interface</h2>\n";
  $out .= "<a href=?>home</a>\n";
  $out .= "<hr/>";
  $out .= "<input type=submit name=action value='Clear Database'>\n";
  $out .= "<hr/>";
  $out .= customer_selectlist_as_html();
  $out .= password_field_as_html();
  $out .= "<hr>Delete oldest <input name=deletecount value=1 /> entries. <input type=submit name='action' value='Delete Entries'><br>\n";
  $out .= "<hr>URL:<input name=url value=http://lp.org><br>UA:<input name=ua value=SomeUA><br>\n";
  $out .= "<input type=submit name='action' value='Create One'>\n";
  $out .= "<hr><b>Test adding lines from log files</b><br>\n";
  $out .= "<textarea rows=3 cols=120 name=data>";
  $out .= get_file_as_string($TEST_FILE);
  $out .= "</textarea><input type=checkbox name=append_to_test_file value=on />Add to defaults file <input type=submit name=action value='add_data'>\n";
  $out .= "</form>\n";
  $out .= "<hr><b>Database Dump</b><br>";
  $out .= get_database_summary_as_html();
  $out .= "<hr>";
  $out .= get_database_as_html();
  output($out);
}

//
// Takes an array of url/ua entries and puts them in the xml
// format that aardvark understands
//
function format_xml_response_for_aardvark($entries) {
  global $TEST_ACA;
  $aca = $TEST_ACA;
  $out = "<?xml version=\"1.0\"?>\n";
  $out .= "<traffic>\n";
  if ($entries != NULL) {
    foreach ($entries as $e) {
      $out .= "  <hit>\n";
      $out .= "    <url>" . $e['url'] . "</url>\n";
      $out .= "    <useragent>" . $e['ua'] . "</useragent>\n";
      $out .= "    <host>" . $aca . "</host>\n";
      $out .= "  </hit>\n";
    }
  }
  $out .= "</traffic>\n";
  return $out; 
}//format_xml_response_for_aardvark


//
//Exit with error if special secret password is not set
//
function check_password() {
  if (isset($_POST['secret']) && ($_POST['secret'] == 'kerry4')) {
    // Do nothing 
  }
  else {
    http_error(401,"Incorrect Password");
  }
}

//
//Creates a database row for the given url, ua and customer code
//
function create_entry($url,$ua,$code) {
        global $TABLENAME;
        $url = mysql_escape_string($url);
        $ua = mysql_escape_string($ua);
        $code = mysql_escape_string($code);
        $q = "insert into " . $TABLENAME . " (url,ua,code,created_epoch_secs) values ('" . $url . "','" . $ua . "','" . $code . "'," . time() . ")";
        $result = db_query($q);
        return ($result != NULL);
}

//
//Clears the database, creating it if it does not exist
//
function create_database() {
    global $CREATE_TABLE_SQL;
    global $DROP_TABLE_SQL;
    
    check_password();
    db_query($DROP_TABLE_SQL);
    db_query($CREATE_TABLE_SQL);
    print "Database created.";
}

//
//Add data to the database.
//The data is expected to be a newline seperated list of url/ua combinations
//The url and ua are seperated by a pipe character.
//
function add_data($code,$data) {
  $linesplitter = "___LINESPLIT___";
  $data = ereg_replace("[\n\r]+",$linesplitter,$data);
  $lines = split($linesplitter,$data);
  foreach ($lines as $line) {
    if (strlen($line) > 10) {
      list($url,$ua) = split('\|',$line);
      $success = create_entry($url,$ua,$code);         
      //FIXME - CHECK $success ???                     
    }
  }
}//add_data

//
// Strips the http:// or https:// from a url.
//
function remove_http($url) {
  $url = str_replace("http://","",$url);
  $url = str_replace("https://","",$url);
  return $url;
}

//
//Redirect the client (assumed to be a mobile) to the given url loaded
//through the ACA.  This happens when a mobile client visits the 
//interface at m.htm when the load a page using this, an entry is created
//for their request (so it can be sent to aardvark and other monitor clients)
//and the client itself is redirected to the ACA to view the page.
//
function mobile_load($url) {
  global $TEST_ACA,$USER_REQUEST_CODE;

  //Create an entry with the special USER_REQUEST_CODE so it can be
  //moved to the top of the queue for instant viewing
  //Also set the user agent of the entry to that which we received from the client
  $success = create_entry($url,$_SERVER['HTTP_USER_AGENT'],$USER_REQUEST_CODE);

  //Send rediret through ACA.
  header("Location: http://" . $TEST_ACA . "/" . remove_http($url));
}

// 
// Returns a UserRequest if one exists else NULL
// 
function get_user_request() {
  global $USER_REQUEST_CODE;
  $q = get_select_query($USER_REQUEST_CODE);
  $r = get_first_row($q);
  if ($r) {
    return row_to_entry($r);          
  }
  else {
    return NULL;
  }
}
//Returns an array of ($count) entries
//If at least 1 entry but not $count are available, those are returned.
//If 0 entries are available NULL is returned.
function get_latest_entries($code = 'any', $count = 1) {
  global $TABLENAME, $COLUMNS, $USER_REQUEST_CODE;
  $out = array();   
  $i = 0;
  $code = mysql_escape_string($code);
  $q = "select " . $COLUMNS . " from " . $TABLENAME . " where code = '" . $code . "' or code = '" . $USER_REQUEST_CODE . "' order by created_epoch_secs desc";
  $result = db_query($q);
  if ($result) {
    $num_rows = mysql_num_rows($result);
    if ($num_rows == 0) {
      return NULL;
    }
    else {                   
      while ($r = mysql_fetch_row($result)) {
        $id = $r[0];                               
        $url = $r[1];                               
        $ua = $r[2];
        $entry = array('id' => $id, 'url' => $url, 'ua' => $ua);        
        array_push($out,$entry);
        $i += 1;
        if ($i == $count) {
          return $out;
        }
      }//end while
      return $out; //return what we have.
    }                        
  }
  else { //No result, return null
    return NULL;
  }
}//get_latest_entries

function dump_as_yaml($cust) {
  $q = get_select_query($cust);
  $result = db_query($q);
  $a = array();
  if ($result) {  
    $myfields = mysql_num_fields($result);
    while ($r = mysql_fetch_row($result)) {
      $e = array('url' => $r[1], 'ua' => $r[2], 'code' => $r[3], 'created_epoch_secs' => $r[4]);
      $a[strval($r[0]) . "_id"] = $e;
    }//end while
  }
  $yaml = Spyc::YAMLDump($a,2,360);
  print_r($yaml);
}

#
# Does a simple sanity check on the data sent up which looks like this:
#
# ...
# http://mycounter.tinycounter.com|BlackBerry7130e/4.1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/104
# http://88.214.227.83|Nokia6133/2.0 (05.60) Profile/MIDP-2.0 Configuration/CLDC-1.1
# http://www.wannawatch.com|SAMSUNG-SGH-A707/1.0 SHP/VPP/R5 NetFront/3.3 SMM-MMS/1.2.0 prof
# ...
#
function is_valid_data($data) {
  return preg_match('/^http:\/\/\S+?\|/',$data);
}


function delete_old_entries($count) {
  global $TABLENAME;
  $q = "SELECT COUNT(*) FROM " . $TABLENAME;
  $first_row = get_first_row($q);
  $total_count = $first_row[0];
  if ($count < $total_count) {
    $q = "delete from " . $TABLENAME . " order by created_epoch_secs ASC limit " . mysql_escape_string($count);
    $result = db_query($q);
    print ($result) ? "OK!" : "FAIL!";
    print " <a href='?action=admin>Go back.</a>";
  }
  else {
    print "Total count is " . $total_count . " and you requested to delete " . $count;
  }
}


//=================================================================


if (isset($_REQUEST['action'])) {

  $action = $_REQUEST['action'];
  if ($action != 'mobile_load') {
    if (! in_array($_SERVER["REMOTE_ADDR"],$approved_ips)) {
      http_error(602,"Bad IP: " . $_SERVER['REMOTE_ADDR']);
    }
  }
  
  if ($action == 'get_next') {  
    $type = param('type');                                      
    $cust = param('cust');
    $count = param('count');                                      
    if (($type != NULL)) {
      get_next($type,$cust,$count);
    }                                 
    else {
      http_error(400,"Type not specified");            
    }                                 
  }
  elseif ($action == 'ie_voyeur') {
    send_ie_voyeur_response();
  }
  elseif ($action == 'mobile_voyeur') {  
  }
  elseif ($action == 'mobile_load') {  
    if (isset($_REQUEST['url'])) {
      mobile_load($_REQUEST['url']);
    }
    else {
      http_error(400,"No url specified");
    }    
  }
  elseif ($action == 'dump_as_yaml') {
          dump_as_yaml(isset($_REQUEST['cust']) ? $_REQUEST['cust'] : NULL);
          exit;
  }

  elseif ($action == 'admin') {  
    print_admin_interface();
  }
  elseif ($action == 'Delete Entries') {  
    check_password();
    #Check this value for numeric
    $count = param('deletecount');
    delete_old_entries($count);
  }
  elseif ($action == 'Clear Database') {  
    check_password();
    $code = param('code');
    if ($code == 'all') {
      create_database();
    }
    else {
      delete_entries_for_code($code);
    }
    print_admin_interface();
  }
  elseif ($action == 'Create One') {  
    //FIXME - Prevent SQL injection HEre !!!!
    create_entry(param('url'),param('ua'),param('code'));
    print_admin_interface();
  }
  elseif ($action == 'add_data') {
    $code = param('code');  
    $data = $_REQUEST['data'];
    $append_to_test_file = isset($_REQUEST['append_to_test_file']);
    if (is_valid_data($data)) {
      if ($append_to_test_file) {
        //Make sure we got the last newline correct
        $data = trim($data) . "\n";
        append_data_to_file($TEST_FILE,$data);
        print "Success. Data added to file '" . $TEST_FILE . "'  <a href='?action=admin>Go back.</a>";
      }
      else {
        add_data($code,$data);
        print "Success. Entries Added.  <a href='?action=admin>Go back.</a>";
      }
    }
    else {
      http_error(601,"Invalid Data:" . $data);
    }
  }

  else {
    print_default_page();
  }

}
else { //no action
  print_default_page();
}

?>
