<?php
include 'nagios_status_log.inc.php';

//Services to check
$video_service_descriptions = array (
'video-check-sites-Vision9-youtube',
'video-check-sites-Vision9-dailymotion',
'video-check-sites-Vision9-espn',
'video-check-sites-Vision9-libero',
'video-check-sites-Vision9-myspace',
'video-check-sites-Vision9-orange');

//Create the log
$log = new NagiosStatusLog('test.log');

//Find each servie and print the html table:
echo "<table border>\n<tr><th>name</th><th>Status</th><th>Last Check</td></tr>\n";
foreach ($video_service_descriptions as $vs) {
  $s = $log->find('service',$vs);
  if (NULL != $s) {
    #echo $s->get_name() . " " . $s->get_status() . " at " . $s->get_timestamp() . "\n";
    echo "<tr><td>" . $s->get_name() . "</td><td>" . $s->get_status() . "</td><td>" . $s->get_timestamp() . "</td></tr>\n";
  }
  else {
    #echo "ERROR COULD NOT FIND SERVICE '" . $vs . "'\n";
    echo "<tr><td colspan=3>ERROR COULD NOT FIND SERVICE '" . $vs . "'</td></tr>\n";
  }
}
echo "</table border>\n";
