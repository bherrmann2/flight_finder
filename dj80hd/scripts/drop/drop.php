<?php

// JAN-22-2008 jwerwath Change Player

$DOCTYPE = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n";

$RELDIR = "drops/";

$FILE_KEY = "drop";
function startsWith($haystack, $needle)
{
    return !strncmp($haystack, $needle, strlen($needle));
}

function endsWith($haystack, $needle)
{
    $length = strlen($needle);
    if ($length == 0) {
        return true;
    }

    return (substr($haystack, -$length) === $needle);
}

function getForm() {
  return <<<END_FORM
  <form enctype="multipart/form-data" method="POST">
  <b>Image:</b>
  <input name="filename" type="file" /><br>
  Password <input type="password" name="secret"><br>
  <input type="submit" name="action" value="drop_in" /></form>
END_FORM;
}

function error_exit($code,$msg)
{
  #http_response_code($code); #PHP 5.4 and above
  header(':', true, $code);
  echo $msg;
  exit;
}

function exitapp($msg)
{
	echo $msg;
	echo "</body></html>\n";
	exit();
}

#e.g. 573822_foo.txt.drop becomes foo.txt
function remove_code_and_suffix($file) {
  $underscore = strpos($file,'_');
  if ($underscore < 0) {
    error_exit(503,'Invalid file name: ' . $file);
  }
  if (! endsWith($file,'.drop')) {
    error_exit(503,'Invalid file name does not end with .drop:' . $file);
  }	
  $drop = strrpos($file,'.drop');

  $realfilename = substr($file,$underscore + 1, $drop - $underscore - 1);
  return $realfilename;
  
  
}

function send_file($file) {
  global $RELDIR;
  #$content = file_get_contents($file);
  #Its all BASE64
  header('Content-type: text/plain');
  $realfilename = remove_code_and_suffix($file);
  header('Content-Disposition: attachment; filename="' . $realfilename . '"');
  #content = r.read().strip()
  
  #echo $content;
  readfile($RELDIR . $file);
}

function code_to_file($code)
{
  global $RELDIR;

  $files = scandir("./" . $RELDIR);
  $needle = $code . "_";
  foreach ($files as $f) {
    if (startsWith($f,$needle)) {
      return $f;
    }
  }
  error_exit(404,"Could not find " . $code . " in " . implode(",",$files));
}

function no_action()
{
  #error_exit(400,"No action");
  echo "HI";
  exit;
}

// ---------------------------------------------- START -----------------
error_reporting(E_ALL);

$out = "";
$out .= "<html><head><title>Blogadder</title></head><body>\n";
$out .= getForm();
$out .= "<hr>\n";



//DEFAULT ACTION IS TO CONVERT
if (!isset($_REQUEST['action'])) {
  no_action();
  
}
if ($_REQUEST['action'] == "drop_upload") {
  if (!isset($_REQUEST['secret']) || $_REQUEST['secret'] != "kerry4") {
    error_exit(403,"YOU ARE NOT AUTHORIZED!"); 
  }	
  if (!isset($_FILES)) {
    error_exit(503,"NO FILES from CGI");
  }
  if (!isset($_FILES[$FILE_KEY])) {
    error_exit(400,"No file in key $FILE_KEY");
  } 
  if (!isset($_FILES[$FILE_KEY]['name'])) {
    error_exit(503,"No file name in key $FILE_KEY");
  } 
  if (!isset($_FILES[$FILE_KEY]['tmp_name'])) {
    error_exit(503,"No file tmp_name in key $FILE_KEY");
  } 

  $name = $_FILES[$FILE_KEY]['name'];
  $tmp_name = $_FILES[$FILE_KEY]['tmp_name'];
  $basename   = basename($name);
  $code = rand(100000,999999);
  #e.g. ./drops/837281_foo.txt.drop
  $target_path = "./" . $RELDIR .  $code . "_" . $basename;
  

  
  #FIXME - NEED MORE CHECKS ON FILE SIZE AND IF IT WAS A SUCCESS
  if(move_uploaded_file($tmp_name, $target_path)) {
    echo $code;
  }else{
    error_exit(503,"UPLOAD ERROR! (tmp_name='" . $tmp_name . "' target_path='" . $target_path . "')");
    print_r($_FILES);
  }//end if (isset($tmp_name)) 
}//end if drop_in
elseif ($_REQUEST['action'] == "drop_download") {
  if (!isset($_REQUEST['code'])) {
    error_exit(400,"No code specified"); 
  }
  $code = $_REQUEST['code'];
  $f = code_to_file($code);
  if (!isset($f)) {
    error_exit(404,"Could not find file for code $code");
  }
  send_file($f);
} 

else {
  error_exit(400,"BAD action: " . $_REQUEST['action']);

}
?>
