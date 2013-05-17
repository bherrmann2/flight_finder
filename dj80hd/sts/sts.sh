function error_exit() {
  msg=$1
  echo $msg
  exit 666
}

function assert_file_exists() {
  filename=$1
  if [ ! -e "$filename"]
  then
    error_exit "$1 does not exist!"
  fi
}

# takes process name as param
function assert_process() {
   process_name=$1
   pgrep_result=`pgrep "$process_name"`
   
   if [ -z "$pgrep_result" ]
   then
     error_exit "Could not find process for $process_name"
   fi
}

#takes comand as input
#sets global cmd_output as output
function get_cmd_output() {
  cmd=$1
  cmd_output=`$cmd`
}
