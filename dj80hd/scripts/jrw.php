<?php
$DEBUG = false;
/**
* 04-17-2006  werwath added hexdump
* 04-MAR-2010 werwath normalize_path_for_windwos
* 09-APR-2011 werwath Merge stuff from lp       
* 16-MAY-2011 add recursive_remove_directory
 */

function recursive_remove_directory($directory, $empty=FALSE)
{
    // if the path has a slash at the end we remove it here
    if(substr($directory,-1) == '/')
    {
        $directory = substr($directory,0,-1);
    }
 
    // if the path is not valid or is not a directory ...
    if(!file_exists($directory) || !is_dir($directory))
    {
        // ... we return false and exit the function
        return FALSE;
 
    // ... if the path is not readable
    }elseif(!is_readable($directory))
    {
        // ... we return false and exit the function
        return FALSE;
 
    // ... else if the path is readable
    }else{
 
        // we open the directory
        $handle = opendir($directory);
 
        // and scan through the items inside
        while (FALSE !== ($item = readdir($handle)))
        {
            // if the filepointer is not the current directory
            // or the parent directory
            if($item != '.' && $item != '..')
            {
                // we build the new path to delete
                $path = $directory.'/'.$item;
 
                // if the new path is a directory
                if(is_dir($path)) 
                {
                    // we call this function with the new path
                    recursive_remove_directory($path);
 
                // if the new path is a file
                }else{
                    // we remove the file
                    unlink($path);
                }
            }
        }
        // close the directory
        closedir($handle);
 
        // if the option to empty is not set to true
        if($empty == FALSE)
        {
            // try to delete the now empty directory
            if(!rmdir($directory))
            {
                // return false if not possible
                return FALSE;
            }
        }
        // return success
        return TRUE;
    }
}

//Check GET and POST for a named parameter, returns null if it does not exist
function get_param($name) {
    if (!isset($_POST) || !isset($_GET)) return null;
    $p = (isset($_POST[$name])) ? $_POST[$name] : null;
    if ($p == null) {
        $p = (isset($_GET[$name])) ? $_GET[$name] : null;
    }
    if ($p != null) $p = mysql_real_escape_string($p);
    return $p;
}

function current_millis() {
    list($usec, $sec) = explode(" ", microtime());
    return round(((float)$usec + (float)$sec) * 1000);
}

function starts_with($haystack, $needle) {
  return ((FALSE !== strpos($haystack,$needle)) &&
	  (0 == strpos($haystack,$needle)));
}

function croak($s) {
  echo $s; die;
}

function normalize_path_for_windows($path)  {
  return str_replace("/","\\" ,$path);
}

function append_file($line,$myFile) {
  touch($myFile);
  $line = normalize_path(trim($line));
  $fh = fopen($myFile, 'a') or die("can't open file");
  fwrite($fh, $line . "\n");
  fclose($fh);
}



function ends_with($Haystack, $Needle){
    // Recommended version, using strpo
    return strrpos($Haystack, $Needle) === strlen($Haystack)-strlen($Needle);
}



function get_args() {
  return $_SERVER['argv'];
}

//Returns an array of all files in a directory
function directoryToArray($directory, $recursive) {
	$array_items = array();
	if ($handle = opendir($directory)) {
		while (false !== ($file = readdir($handle))) {
			if ($file != "." && $file != "..") {
				if (is_dir($directory. "/" . $file)) {
					if($recursive) {
						$array_items = array_merge($array_items, directoryToArray($directory. "/" . $file, $recursive));
					}
					$file = $directory . "/" . $file;
					$array_items[] = preg_replace("/\/\//si", "/", $file);
				} else {
					$file = $directory . "/" . $file;
					$array_items[] = preg_replace("/\/\//si", "/", $file);
				}
			}
		}
		closedir($handle);
	}
	return $array_items;
}


function get_script_absolute_base_url() {
  $script_uri = $_SERVER['SCRIPT_URI'];
  $lastslash = strrpos($script_uri,"/");
  if ($lastslash > 0) {
    $script_uri = substr($_SERVER['SCRIPT_URI'],0,$lastslash + 1);
  }
  return $script_uri;
}

//e.g. strToHex("jim") returns "6a696d"
function strToHex($string)
{
    $hex='';
    for ($i=0; $i < strlen($string); $i++)
    {
        $hex .= dechex(ord($string[$i]));
    }
    return $hex;
}

//e.g. hexToStr("474554") returns "GET"
function hexToStr($hex)
{
    $string='';
    for ($i=0; $i < strlen($hex)-1; $i+=2)
    {
        $string .= chr(hexdec($hex[$i].$hex[$i+1]));
    }
    return $string;
}


//for example: script at http://www.foo.com/php/scripts/foo.php?x=3
//would return /php/scripts/foo.php
function getRootRelativeScriptPath()
{
	$path_parts = pathinfo($_SERVER['SCRIPT_NAME']);
	return $path_parts['dirname'] . "/" . $path_parts['basename'];
	
}
function string2file($string, $filename)
{
  //FIXME - better error handling
  $fh = fopen($filename, 'w') or die("can't open file");
  fwrite($fh, $string);
  fclose($fh);
}

function redirect($location) {
    header('Location: ' . $location);
    die();
}
function is_empty($x) {
    if ($x == null) return true;
    if (is_array($x)) return (count($x) < 1);
    if (strlen($x) == 0) return true;
    if (preg_match('/^\s+$/',$x)) return true;
    return false;
}

//Convenience method that does all error checking and returns null for
//accessing associative arrays like $an_array['foo']
function hashval($a,$key) {
    if ($a != null) {
        if (is_array($a)) {
            if (isset($a[$key])) {
                return $a[$key];
            }
        }
    }
    return null;
}

function file2string($f) {
  //One could probably use file_get_contents
  $fh = fopen($f,'r') or die($php_errormsg);
  $content = fread($fh,filesize($f));
  fclose($fh) or die($php_errormsg);
  return $content;
}

//Coverts a file to a has of values
//Each non-empty line is split by the first : character.
function file2hash($f) {
  $h = array();
  $lines = file($f);
  foreach ($lines as $line) {
    //If not comment and not whitespace
    if (!starts_with($line,"#") && !is_empty($line)) {
      //Split the name value pair like we see in a jad file
      list($name,$value) = explode(':',$line,2);
      //If the split worked as expected, add to hash, trimming any whitespace
      if (!is_empty($name) && !is_empty($value)) {
        $h[trim($name)] = trim($value);
      }
    }
  }//foreach
  return $h;
}

function hash2string($h,$delimeter = ':') {
  $out = "";
  foreach (array_keys($h) as $key) {
    $out = $out . $key . $delimeter . $h[$key] . "\n";
  }
  return $out;
}
function hash2file($h, $filename, $delimeter = ':') {
  $fh = fopen($filename, 'w') or die("can't open file");
  $out = hash2string($h,$delimeter);
  fwrite($fh,$out);
  fclose($fh);
}

function head($s,$maxlen)
{
	$slen = strlen($s);
	if ($slen <= $maxlen)
	{
		return $s;
	}
	else
	{
		return substr($s,0,$maxlen); 
	}
}
function tail($s,$maxlen)
{
	$slen = strlen($s);
	if ($slen <= $maxlen)
	{
		return $s;
	}
	else
	{
		return substr($s,($slen - $maxlen),$maxlen); 
	}
}
/**
 * View any string as a hexdump.
 *
 * This is most commonly used to view binary data from streams
 * or sockets while debugging, but can be used to view any string
 * with non-viewable characters.
 *
 * @version     1.3.2
 * @author      Aidan Lister <aidan@php.net>
 * @author      Peter Waller <iridum@php.net>
 * @link        http://aidanlister.com/repos/v/function.hexdump.php
 * @param       string  $data        The string to be dumped
 * @param       bool    $htmloutput  Set to false for non-HTML output
 * @param       bool    $uppercase   Set to true for uppercase hex
 * @param       bool    $return      Set to true to return the dump
 */
function hexdump ($data, $htmloutput = true, $uppercase = false, $return = false)
{
    // Init
    $hexi   = '';
    $ascii  = '';
    $dump   = ($htmloutput === true) ? '<pre>' : '';
    $offset = 0;
    $len    = strlen($data);
 
    // Upper or lower case hexidecimal
    $x = ($uppercase === false) ? 'x' : 'X';
 
    // Iterate string
    for ($i = $j = 0; $i < $len; $i++)
    {
        // Convert to hexidecimal
        $hexi .= sprintf("%02$x ", ord($data[$i]));
 
        // Replace non-viewable bytes with '.'
        if (ord($data[$i]) >= 32) {
            $ascii .= ($htmloutput === true) ?
                            htmlentities($data[$i]) :
                            $data[$i];
        } else {
            $ascii .= '.';
        }
 
        // Add extra column spacing
        if ($j === 7) {
            $hexi  .= ' ';
            $ascii .= ' ';
        }
 
        // Add row
        if (++$j === 16 || $i === $len - 1) {
            // Join the hexi / ascii output
            $dump .= sprintf("%04$x  %-49s  %s", $offset, $hexi, $ascii);
            
            // Reset vars
            $hexi   = $ascii = '';
            $offset += 16;
            $j      = 0;
            
            // Add newline            
            if ($i !== $len - 1) {
                $dump .= "\n";
            }
        }
    }
 
    // Finish dump
    $dump .= $htmloutput === true ?
                '</pre>' :
                '';
    $dump .= "\n";
 
    // Output method
    if ($return === false) {
        echo $dump;
    } else {
        return $dump;
    }
}

?>
