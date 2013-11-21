<?php

/**
* Abstraction for all parts (info,program,service,host) that can appear
* in a status log.  This is the parent class for all specific sections.
* 
* The main interface points for the NagiosStatusLog class are as follows:
* //create a log
* $log = new NagiosStatusLog('status.log');
*
* //get a hash of the 'info' parameters
* $info_params = $log->get_info();
*
* //get the 'program' parameters
* $info_params = $log->get_program();
*
* //get an array of all the services (ServiceStatusLogSection objects)
* $services_array = $log->get_services();
*
* //get an array of all the hosts (HostStatusLogSection objects)
* $hosts_array = $log->get_services();
*
* //find a given service
* $youtube_check = $log->find('service','video-check-sites-Vision9-youtube');
*
* //print the parameters of that service
* if (isset($youtube_check)) {
*   $params = $youtube_check->params();
*   $params_keys = array_keys($params);
*   foreach ($param_keys as $key) {
*     echo "Parameter " . $key . " has value '" . $params[$key] . "'\n";
*   }
* }
*
*/
class StatusLogSection {
  //Hash of all parameters in the section
  //Normally, this is private and an accessor method is provided.  This direct access, however, makes
  //the client interface simpler
  var $params;

  function StatusLogSection($hash) {
    $this->params = $hash;
  }

  /**
  * Name is NULL by default (info and program sections do not have names)
  */
  function get_name() {
    return NULL;
  }
}//end StatusLogSection

/**
* This class abstracts the parts of Host and Service Sections that are common.
*/
class BasicStatusLogSection extends StatusLogSection {
  var $statuses = array(0 => "OK",1 => "WARNING",2 => "ERROR",3 => "UNKNOWN");
  function BasicStatusLogSection($hash) {
    parent::__construct($hash);
  }
  function get_status() {
    return $this->statuses[$this->params['current_state']];
  }
  function get_timestamp() {
    return strftime("%c",$this->params['last_update']);
  }
}


/**
* Abstraction for the Host Sections in a Status log
*/
class HostStatusLogSection extends BasicStatusLogSection {
  function HostStatusLogSection($hash) {
    parent::__construct($hash);
  }
  function get_name() {
    return $this->params['host_name'];
  }
}


/**
* Abstraction for the Service Sections in a Status log
*/
class ServiceStatusLogSection extends BasicStatusLogSection {
  function ServiceStatusLogSection($hash) {
    parent::__construct($hash);
  }
  function get_name() {
    return $this->params['service_description'];
  }
}


/**
* A collection of Status Log Sections
*/
class StatusLogSectionCollection {
  
  var $impl;

  function StatusLogSectionCollection() {
    $this->impl = array();                    
  }

  function dump() {
    print_r($this->impl);
  }                     
 
  /**
  * Add this log section to the array of the appropriate type
  */ 
  function add($type,$status_log_section) {
    //Create the array for this type if it does not yet exist
    if (!(isset($this->impl[$type]) && is_array($this->impl[$type]))) {
      $this->impl[$type] = array();
    }
    //Add it to the array                                       
    array_push($this->impl[$type],$status_log_section);         
  }
 
  function find($type,$name = NULL) {
    //Get the array of StatusLogSections of this type...
    $a = $this->impl[$type];
    //Return NULL if there is no array of that type.
    if (!(isset($a) && is_array($a))) {
      return NULL;
    }
    //print_r($a);
    //Find  match based on name and return it.
    foreach ($a as $status_log_section) {
      if (isset($status_log_section)) {
        //print_r($status_log_section);
        if ($status_log_section->get_name() == $name) {
          return $status_log_section;
        }                                 
      }
    }
    //If we got here we did not find it.
    return NULL;
  }
}// class StatusLogSectionCollection


/**
* This class provides a Factory Method to create a Status Log Section
* Object of the given type (info,program,service,host)
*/
class StatusLogSectionFactory {
  function create($type,$params) {
    if ($type == 'info') {
      return new StatusLogSection($params);
    }
    else if ($type == 'program') {
      return new StatusLogSection($params);
    }
    else if ($type == 'service') {
      return new ServiceStatusLogSection($params);
    }
    else if ($type == 'host') {
      return new HostStatusLogSection($params);
    }
    else {
      return NULL;
    }
  }//end fuction create
}//end class StatusLogSectionFactory

/**
* Abstraction for the entire log
*/
class NagiosStatusLog {
  var $sections;       

  /**
  * Returns a hash of the info for this log
  */
  function info() {
    return $this->sections->find('info');
  } 
  function program() {
    return $this->sections->find('program');
  } 

  function find($type,$name) {
    $s = $this->sections;
    return (isset($s)) ? $s->find($type,$name) : NULL;
  }
  /**
  * Debug method to dump the log 
  */
  function dump() {
    echo "STATUS LOG DUMP:\n";
    $s = $this->sections->dump();
  }

  /**
  * Convenience method to write a string as a line to STDOUT
  */
  private function puts($s) {
    echo $s . "\n";   
  }

  function NagiosStatusLog($filename) {
    $factory = new StatusLogSectionFactory();
    $this->sections = new StatusLogSectionCollection();
    $lines = file($filename);
    $current_params = NULL;
    $current_type = NULL;
    $line_count = 0;
    foreach ($lines as $line) {
      $line_count++;
      //start of something important
      if (preg_match('/^(\w+) {/',$line,$regs)) {

        //e.g. holds all the parameters of a service,host,etc.
        $current_params = array();                         

        //e.g. is the type (service or host or ????)              
        $current_type = $regs[1];                         
      }                                        
      else if (preg_match('/^\s(\w+)=(.*)/',$line,$regs)) {
        if (isset($current_params)) {
          $current_params[$regs[1]] = $regs[2];
        }
        else {
          throw new Exception("PAIR in ". $filename . " at line " 
          . " at line " . $line_count . " arrived out of order");
        }
      }
      //Matches the end brace } at the end of a section
      else if (preg_match('/^\s*\}\s*$/',$line,$regs)) {
        $section = $factory->create($current_type,$current_params);
        $this->sections->add($current_type,$section);
      }                                        
    }//end foreach line                     
  }//end NagiosStatusLog constuctor
}//end class NagiosStatusLog
