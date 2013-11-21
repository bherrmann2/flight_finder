#!/bin/sh
# FILE: "/usr/local/groundwork/nagios/libexec/check_bandwidth"
# LAST MODIFICATION: "Thu, 01 Jul 2004 11:25:23 -0500 (root)"
# (C) 2004 by Ryan Langseth, <langseth@cs.und.edu>
# $Id:$
#
#
#  This Nagios plugin was created to check the bandwidth currently being used on a cisco 6509 router Gi port
#

PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: .2 $' | sed -e 's/[^0-9.]//g'`

. $PROGPATH/utils.sh

print_usage() {
  echo "Usage:"
  echo "  $PROGNAME -o <OID> -H <hostname> -w <warning level> -c <critical level> [-p <community string>] "
  echo "  $PROGNAME -h "

  
}

print_help() {
  print_revision $PROGNAME $REVISION
  echo ""
  print_usage
  
	echo "Check current bandwidth usage for specific counter on a 6509 cisco router"
	echo ""
	echo "Options:"
	echo "	-o the OID to check"
	echo "	-p the community string (defaults to 'public')"
	echo "	-H host name"
	echo "	-w warning level"
	echo "	-c critical level"
	echo "	-h display help screen"
	echo ""
	echo ""
  support
  exit $STATE_UNKNOWN
}



STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

HOST=`hostname`

COMMSTR="public"
OID=""
SNMPWALK=`which snmpwalk`
critLvl=0
warnLvl=1

if [ $# -le 2 ]; then
	echo ""
	print_usage
	echo "Not enough options given"
	exit $STATE_UNKNOWN
fi
	
while getopts ":o:p:H:w:c:h" Option
do
# o is the OID for the snmp check
# p is the community String
# H is the Host name
# w is the warning level 
# c is the critical level 
# h is to display the help screen

	case $Option in 
		o ) OID=$OPTARG;;
		p ) COMMSTR=$OPTARG;;
		H ) SNMPHOST=$OPTARG;;
		w ) warnLvl=$OPTARG;;
		c ) critLvl=$OPTARG;;
		h ) print_help;;
		* ) echo "unimplemented option";;
		
		esac
done
	
	shift $((OPTIND - 1))

if [ $warnLvl -ge  $critLvl ] ; then 
	echo ""
	echo "Warning Level must be less than Critical Level"
	echo ""
	
	print_help
fi


if [ ! $SNMPHOST ] ; then 
	echo " Error - No SNMP Host given "
	echo ""
	print_help
	echo ""
fi

if [ $SNMPWALK == "" ] ; then
	`echo "WARNING - snmpwalk not installed on $HOST"`
	exit $STATE_UNKNOWN
fi

#Query the host for counter 
FIRST=`$SNMPWALK $SNMPHOST $COMMSTR $OID`
FIRST=`echo $FIRST | awk '{print $4}'`
if [ ! $FIRST  ] ; then
	echo "WARNING - No response from snmp query"
	exit $STATE_WARNING
fi

sleep 5

SECOND=`$SNMPWALK $SNMPHOST $COMMSTR $OID`
SECOND=`echo $SECOND | awk '{print $4}'`
if [ ! $SECOND  ] ; then
	echo "WARNING - No response from snmp query"
	exit $STATE_WARNING
fi



OUTPUT=`expr "(" "(" $SECOND "-" $FIRST ")" "*" 8 ")"  "/" 5000000`

FOO=`expr $OUTPUT ">=" $critLvl`
if [ $FOO == "1" ] ; then
	echo "CRITICAL - Bandwidth on Gi3/2 is $OUTPUT mb/s" 
	exit $STATE_CRITICAL
fi

FOO=`expr $OUTPUT ">=" $warnLvl`
if [ $FOO == "1" ] ; then
	echo "WARNING - Bandwidth on Gi3/2 is $OUTPUT mb/s" 
	exit $STATE_WARNING
fi

echo "OK - Bandwidth on Gi3/2 is $OUTPUT mb/s"
exit $STATE_OK
echo $OUTPUT

