<?php

include 'nagios_status_log.inc.php';

$video_service_descriptions = array (
'video-check-sites-Vision9-youtube',
'video-check-sites-Vision9-dailymotion',
'video-check-sites-Vision9-espn',
'video-check-sites-Vision9-libero',
'video-check-sites-Vision9-myspace',
'video-check-sites-Vision9-orange');

$log = new NagiosStatusLog('status.log');

foreach ($video_service_descriptions as $vs) {
  $s = $log->get_first('service','service_description',$vs);
  if (NULL != $s) {
    echo $s->get_name() . " " . $s->get_status() . " at " . $s->get_timestamp() . "\n";
  }
  else {
    echo "ERROR COULD NOT FIND SERVICE '" . $vs . "'\n";
  }
}
