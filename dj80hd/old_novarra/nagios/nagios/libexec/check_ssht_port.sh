#!/bin/sh

_tmp=/tmp/check_ssht_port.$$.out

function exeunt
{
  rm -f ${_tmp}
  [ "$2" != "" ] && echo $2
  [ "$1" != "" ] && exit $1
  exit 0
}

_USAGE="Usage: $0 host [port]";

trap exeunt SIGHUP SIGINT SIGTERM

_PRODUCTION="true"  # set to something other than "true" for pre-prod
_PORT=8080
case $# in
  1)
      _EWD=${1}
      if [[ "-h" = "${1}" ]]
      then
         exeunt "0" "$_USAGE"
      fi
      ;;
  2)
      _EWD=${1}
      _PORT=${2}
      ;;
  *)
      exeunt "2" "Invalid syntax.\n\n${_USAGE}"
      ;;
esac
#jrw file:///home/novarra/test.html does not exist.  Talked to Nemik he said
# just use live google for a check.
#fullUrl="http://${_EWD}:${_PORT}/snapshot?url=file:///home/novarra/test.html"
fullUrl="http://${_EWD}:${_PORT}/snapshot?url=www.froogle.com"

_wget=`which wget 2>/dev/null`
if [[ ${_PRODUCTION} != "true" ]]
then
  if [[ "" = ${_wget} || ! -f ${_wget} || ! -x ${_wget} ]]
  then
    exeunt "2" "EWD Error while processing [${fullUrl}] -- cannot find [wget]."
  fi
fi

_cmd="${_wget} -T 20 -w 6 -t 1 -o ${_tmp} -O /dev/null ${fullUrl}"
#echo ${_cmd}
if [[ "${_PRODUCTION}" != "true" ]]
then
  echo "Would've executed this: [${_cmd}]"
fi
${_cmd} > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
 exeunt "2" "[SNAPSHOT:${_EWD}] - TIMEOUT AFTER 20s ${_cmd}"
fi

##_conn_line=`cat ${_tmp} | egrep "^Connecting to ${_EWD}:${_PORT}..."`
_conn_line=`cat ${_tmp} | egrep "^Connecting to "`
if [[ "${_conn_line}" = "" ]]
then
  exeunt "2" "[SNAPSHOT:${_EWD}] - UNKNOWN CONN ERROR] ${_cmd}"
fi
_conn_status=`echo ${_conn_line} | cut -d" " -f4-`
if [[ "${_conn_status}" != "connected." ]]
then
  exeunt "2" "[SNAPSHOT:${_EWD}] - ERROR [${_conn_status}] ${_cmd}"
fi
_to_eol=`cat ${_tmp} | egrep '^HTTP request sent, awaiting response...' | cut -c41-`
if [[ "${_to_eol}" = "" ]]
then
  exeunt "2"  "[SNAPSHOT:${_EWD}] - NO HTTP RSP ${_cmd}"
fi
_rsp=`echo "${_to_eol}" | cut -c-3`
if [[ "200" = "${_rsp}" ]]
then
  exeunt "0" "[SNAPSHOT:${_EWD}] - 200 OK ${_cmd}" 
else
  exeunt "2" "[SNAPSHOT:${_EWD}] - !200 OK - ${_rsp} ${_cmd}"
fi

exeunt "1" "no msg"
