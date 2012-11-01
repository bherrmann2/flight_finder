<?php
include('simple_html_dom.php');
include('URL.php');

function make_absolute($base) {
  $ua = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1";
  $headers = array(
          "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
$opts = array(
  'http'=>array(
          'header'=>"User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1\r\n" .
          "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" .
          "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7"
  )
);
$context = stream_context_create($opts);
$html = file_get_html($base,false,$context);
/*
  $c = curl_init($base);
  curl_setopt($c,CURLOPT_RETURNTRANSFER,1);
  curl_setopt($c,CURLOPT_HTTPHEADER, $headers);
  curl_setopt($c,CURLOPT_USERAGENT, $ua);
  $page = curl_exec($c);
  $basehref = curl_getinfo($c,CURLINFO_EFFECTIVE_URL);
  curl_close($c);
  $html = str_get_html($page);
 */

  
  foreach($html->find('link') as $e) {
    $href = $e->href;
    $url =& new URL($base);
    $url->set_relative($href);
    $e->href = $url->as_string();
  }
  foreach($html->find('a') as $e) {
    $href = $e->href;
    $url =& new URL($base);
    $url->set_relative($href);
    $e->href = $url->as_string();
  }
  foreach($html->find('img') as $e) {
    $src = $e->src;
    $url =& new URL($base);
    $url->set_relative($src);
    $e->src = $url->as_string();
  }

  #FIXME - this base has actually got to e what we are redirected to !!!
  foreach ($html->find('head') as $head) {
    $head->innertext = "<base href=\"" . $base . "/\"/>" . $head->innertext;
  }
    
  return $html;
}

if (isset($_GET['base'])) {
  print make_absolute($_GET['base']);
}
else {
print "<form>URL:<input name=base value='http://'><input type=submit value=Go></form>";
}

?>
