#!/bin/bash
# This script is designed to be used by Nagios. It checks for the availability of both Microsoft SQL Server 7 and 2000.
#
# Requirements:
#
# FreeTDS (http://www.freetds.org/)
#
# Changed to call FreeTDS innstead of SQSH
# Oct 25 2004 -- use bash instead of sh otherwise Solaris won't work
#
freetdscmd="/usr/local/bin/tsql"
sqshcmd="/usr/local/bin/sqsh"
catcmd=`which cat`
grepcmd=`which grep`
rmcmd=`which rm`
mktempcmd=`which mktemp`
wccmd=`which wc`
sedcmd=`which sed`
trcmd=`which tr`
uniqcmd=`which uniq`

###################################################################################################################


hostname=$1
usr=$2
pswd=$3
srv=$4

echo "Starting script..."
if [ ! "$#" == "4" ]; then
        echo -e "\nYou did not supply enough arguments. \nUsage: $0 <host> <username> <password> <version> \n \n$0 checks Microsoft SQL Server connectivity. It works with versions 7 and 2000.\n\nYou need a working version of Sqhs (http://www.sqsh.org/) and FreeTDS (http://www.freetds.org/) to connect to the SQL server. \nIt was written by Tom De Blende (tom.deblende@village.uunet.be) in 2003. \n\nExample:\n $0 dbserver sa f00bar 2000\n" && exit "3"

elif [ $sqshcmd == "" ]; then
	echo -e "Sqsh not found! Please verify you have a working version of Sqsh (http://www.sqsh.org/) and enter the full path in the script." && exit "3"

fi

exit="3"

echo "Checking SQL version.."
# Creating the command file that contains the sql statement that has to be run on the SQL server. Normally one would use the -C parameter of sqsh, but it seems that there is a bug that doesn't allow statements with more than one blanc.

tmpfile=`$mktempcmd /tmp/$hostname.XXXXXX`

if [ $srv == "7" ]; then
        spid=7
elif [ $srv == "2000" ]; then
        spid=50
else
	echo -e "$srv is not a supported MS SQL Server version!" && exit "3"
fi

# echo -e "select loginame from sysprocesses where spid > $spid order by loginame asc\ngo" > $tmpfile

echo -e "EXEC sp_helpdb" > $tmpfile

# Running sqsh to get the results back.

resultfile=`$mktempcmd /tmp/$hostname.XXXXXX`
#$sqshcmd -S $hostname -U $usr -P $pswd -w 100000 -i $tmpfile -o $resultfile -b -h 2>/dev/null
#$resultfile << EOF
$freetdscmd -S $hostname -U $usr -P $pswd >$resultfile << EOF
exit
EOF

if [ ! -s $resultfile ]; then
	$rmcmd -f $tmpfile $resultfile;
	echo CRITICAL - Could not make connection to SQL server.;
	exit 2;
fi

#Check if we got the command prompt

result=`$grepcmd "1>" $resultfile`

if [ $result ]; then
        $rmcmd -f $tmpfile $resultfile;
        echo "OK - MS SQL Server $srv has $nmbr user(s) connected: $users" | sed 's/: $/./g';
        exit 0;

else
	$rmcmd -f $tmpfile $resultfile;
	echo CRITICAL - Could not make connection to SQL server.;
	exit 2;
fi


# Cleaning up.

$rmcmd -f $tmpfile $resultfile
echo $stdio
exit $exit
