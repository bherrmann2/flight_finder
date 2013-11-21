#!/bin/sh
 
_tmp=/tmp/check_ewd_port.$$.$RANDOM
 
function exeunt
{
  rm -f ${_tmp}
  [ "$2" != "" ] && echo $2
  [ "$1" != "" ] && exit $1
  exit 0
}
 
trap exeunt SIGHUP SIGINT SIGTERM
 
_PORT=8827
case $# in
  1)
      _EWD=${1}
      ;;
  2)
      _EWD=${1}
      _PORT=${2}
      ;;
  *)
      exeunt "2" "invalid syntax"
      ;;
esac
fullUrl="http://${_EWD}:${_PORT}/KEEPALIVE"
 
##############################################################################
# swhitney, 08 Feb 07: removed dependency on old perl
#### status=`/usr/local/bin/perl/GET -ds ${fullUrl}`
##############################################################################
_wget=`which wget 2>/dev/null`
if [[ "" = ${_wget} || ! -f ${_wget} || ! -x ${_wget} ]]
then
  exeunt "2" "EWD Error while processing [${fullUrl}] -- cannot find [wget]."
fi
 
_cmd="${_wget} -T5 -o ${_tmp} -O /dev/null ${fullUrl} >/dev/null 2>&1"
## echo "${_cmd}"
${_cmd}
##_conn_line=`cat ${_tmp} | egrep "^Connecting to ${_EWD}:${_PORT}..."`
_conn_line=`cat ${_tmp} | egrep "^Connecting to "`
if [[ "${_conn_line}" = "" ]]
then
  exeunt "2" "[ACA:${_PORT}] - UNKNOWN CONN ERROR]"
fi
_conn_status=`echo ${_conn_line} | cut -d" " -f4-`
if [[ "${_conn_status}" != "connected." ]]
then
  exeunt "2" "[ACA:${_PORT}] - ERROR [${_conn_status}]"
fi
_to_eol=`cat ${_tmp} | egrep '^HTTP request sent, awaiting response...' | cut -c41-`
if [[ "${_to_eol}" = "" ]]
then
  exeunt "2"  "[ACA:${_PORT}] - NO HTTP RSP"
fi
_rsp=`echo "${_to_eol}" | cut -c-3`
if [[ "200" = "${_rsp}" ]]
then
  exeunt "0" "[ACA:${_PORT}] - 200 OK"
else
  exeunt "2" "[ACA:${_PORT}] - !200 OK - ${_rsp}"
fi
 
exeunt "0" "no msg"
