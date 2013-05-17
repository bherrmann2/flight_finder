source ./sts.sh

#error_exit "BLAH2"
#assert_process sendmails
get_cmd_output "ls /tmp"
echo $cmd_output
