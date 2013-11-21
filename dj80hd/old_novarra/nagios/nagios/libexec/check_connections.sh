#! /bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`


print_usage() {
	echo "Usage: $PROGNAME <warn> <crit>"
}

print_help() {
	print_revision $PROGNAME $REVISION
	echo ""
	print_usage
	echo ""
	echo "This plugin checks established connections using netstat."
	echo ""
	exit 0
}

# Grab the command line arguments
                                                                                                                         

if test "$1" = "" -o "$2" = ""; then
	print_usage
	exit 1
fi

WARNING=$1
CRITICAL=$2
exitstatus=$STATE_WARNING #default

case "$1" in
	--help)
		print_help
		exit 0
		;;
	-h)
		print_help
		exit 0
		;;
	--version)
   	print_revision $PROGNAME $REVISION
		exit 0
		;;
	-V)
		print_revision $PROGNAME $REVISION
		exit 0
		;;
	*)
		count=`netstat | grep ESTABLISHED | wc -l 2>&1`
		status=$?
		if test "$1" = "-v" -o "$1" = "--verbose"; then
			echo ${count}
		fi
		if test ${status} == 127 ; then
			echo "STATUS UNKNOWN - command not found."
			exit -1
		elif test ${status} == 0 ; then
			if (( ${count} < ${WARNING} )) ; then
				echo "ok - ${count} connections"
			exit 0
			elif (( ${count} >= ${WARNING} ))  ; then
				if (( ${count} > ${CRITICAL} )) ; then
					echo "CRITICAL - ${count} connections"
					exit 2
				else
					echo "WARNING - ${count} connections"
					exit 1
				fi
			fi
		fi
		;;
esac
