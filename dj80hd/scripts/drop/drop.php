<?php

// JAN-22-2008 jwerwath Change Player

$DOCTYPE = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n";

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
  http_response_code($code);
  echo $msg
}

function exitapp($msg)
{
	echo $msg;
	echo "</body></html>\n";
	exit();
}

function get_html($img_url)
{
  global $_REQUEST;
  $output = "<img src='" . $img_url . "'/><br/>\n";
  return $output . "<hr>\n<textarea rows=20 cols=40>" . $output . "</textarea>";

}
function send_file($file) {
  $content = file_get_contents ($file);
  #Its all BASE64
  header('Content-type: text/plain');
  echo $content
}

function file_for_code($code)
{
  $dir = "./" . $reldir;
  $files = scandir($dir);
  $needle = $code . "_";
  foreach ($files as $f) {
    if (startsWith($f,$needle)) {
      return $f;
    }
  }
  return;
}

// ---------------------------------------------- START -----------------
error_reporting(E_ALL);

out = $DOCTYPE;
out .= "<html><head><title>Blogadder</title></head><body>\n";
out .= getForm();
out .= "<hr>\n";

$rel_dir = "drops/"
$base_url = "http://scissorsoft.com/pix/";

//DEFAULT ACTION IS TO CONVERT
if (isset($_REQUEST['action']) && $_REQUEST['action'] == "Add")
{
  if (!isset($_REQUEST['action']) {
    error_exit(400,"No action");
  }
  if ($_REQUEST['action'] == "drop_in") {

    if (!isset($_REQUEST['secret']) || $_REQUEST['secret'] != "kerry4") {
      error_exit(403,"YOU ARE NOT AUTHORIZED!");                                
    }
    else {
      $urls['filename'] = NULL;
      $file_keys = array('filename');
      foreach ($file_keys as $key) {
        $basename   = basename( $_FILES[$key]['name']); 
	    #FIXME - still a chance of dups here ?
		$code = rand(100000,999999);
		#FIXME - Create path if it does not exist
        $target_path = "./" . $reldir .  $code . "_" . $basename;
        $tmp_name = $_FILES[$key]['tmp_name']; 
		#FIXME - NEED MORE CHECKS ON FILE SIZE AND IF IT WAS A SUCCESS
        if (isset($tmp_name)) {
          if(move_uploaded_file($tmp_name, $target_path)) {
            #echo "File ".  basename($tmp_name) .  " uploaded";
            $urls[$key] = $base_url . $basename;
          }
          else {
            error_exit(503,"UPLOAD ERROR! (tmp_name='" . $tmp_name . "' target_path='" . $target_path . "')";
            print_r($_FILES);
          }//end if(move_upload ..
        }//end if(isset
      }//end foreach
      echo get_html($urls['img']);
    }
  }
  elseif ($_REQUEST['action'] == "drop_out") {
    if (isset($_REQUEST['code'])) {
	  $f = code_to_file($code);
	  if (isset($f)) {
	    send_file($f);
	  }
	  else {
	    error_exit(404,"Could not find file for code $code");
	  }
	}
	else {
	  error_exit(400,"No code specified")
	}
  }
  else {
    error_exit(400,"BAD action: " . $_REQUEST['action'])
  }
}
?>
