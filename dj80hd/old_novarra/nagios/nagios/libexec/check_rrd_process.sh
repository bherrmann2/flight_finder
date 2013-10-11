#!/bin/bash

function_usage()
{
cat << EOF
usage: $0 options

OPTIONS:
-h      Host address
EOF
}

while getopts "h:t:" options; do
    case $options in
      h ) host=$OPTARG;;
      * ) fuction_usage
           exit 1;;
    esac
done

type_compare=`ssh $host "ps ax | grep perl" | awk '{print $6}'`
status_code=4
status_text="Critical: rrd-graph-and-upload, generate-rrds-from-content-unified, rrd-graph-and-upload.ERRORS, generate-rrds-from-unified not found"

for i in $(echo $type_compare | sed 's: :\n:g'); do
    a=$(echo $i | awk '{if (/rrd-graph-and-upload$/) print "1" ; else print "0"}')
    if [ $a -eq 1 ] ; then
        status_text=`echo $status_text | sed 's: rrd-graph-and-upload,::g'`
        status_code=$[$status_code-1]
    fi
    b=$(echo $i | awk '{if (/generate-rrds-from-content-unified.*$/) print "1" ; else print "0"}')
    if [ $b -eq 1 ] ; then
        status_text=`echo $status_text | sed 's: generate-rrds-from-content-unified,::g'`
        status_code=$[$status_code-1]
    fi
    c=$(echo $i | awk '{if (/rrd-graph-and-upload.ERRORS$/) print "1" ; else print "0"}')
    if [ $c -eq 1 ] ; then
        status_text=`echo $status_text | sed 's: rrd-graph-and-upload.ERRORS,::g'`
        status_code=$[$status_code-1]
    fi
    d=$(echo $i | awk '{if (/generate-rrds-from-unified.*$/) print "1" ; else print "0"}')
    if [ $d -eq 1 ] ; then
        status_text=`echo $status_text | sed 's: generate-rrds-from-unified::g'`
        status_code=$[$status_code-1]
    fi
done

if [ $status_code -eq 0 ]; then
    echo OK
    exit 0
else
    echo $status_text
    exit 2
fi
