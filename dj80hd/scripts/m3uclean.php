<?php

function string2file($string, $filename)
{
  //FIXME - better error handling
  $fh = fopen($filename, 'w') or die("can't open file");
  fwrite($fh, $string);
  fclose($fh);
}
function ends_with($Haystack, $Needle){
    // Recommended version, using strpo
    return strrpos($Haystack, $Needle) === strlen($Haystack)-strlen($Needle);
}

function starts_with($haystack, $needle)
{
  return ((FALSE !== strpos($haystack,$needle)) &&
	  (0 == strpos($haystack,$needle)));
}//starts_with
function croak($s)
{
  echo $s; die;
	
}
$USAGE = "php m3uclean <m3u_file> <root_dir>\n";
$USAGE .= "Note, root_dir is optional. If blank it is assumed that m3u file contains absolute pathnames.\n";

$m3ufile = NULL;
$rootdir = NULL;
$args = $_SERVER['argv'];
if (isset($args[1]))
{
  $m3ufile = $args[1];
  echo "M3U:$m3ufile\n";             
  if (!file_exists($m3ufile)) croak("This file does not exist: $m3ufile\n");
}
if (isset($args[2]))
{
  $rootdir = $args[2];
  echo "ROOT:$rootdir\n";             
  if (!is_dir($rootdir)) croak("This is not a directory: $rootdir\n");
  if (!ends_with($rootdir,"\\")) croak("Directory must end with a backslash: $rootdir\n");
}
if ($m3ufile == NULL) croak($USAGE);
$lines = file($m3ufile);
$out = "";
foreach ($lines as $lineno => $line)
{
  if (($lineno % 100) == 0) echo ".";
  $line = trim($line);
  if (!starts_with($line,"#") && strlen($line)>0)
  {
    if ($rootdir != NULL) $line = $rootdir . $line;
    if (file_exists($line)) $out .= "$line\n";
  }
}
string2file($out,$m3ufile);
?>
