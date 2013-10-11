#!/bin/bash
SQL_HOST=$1
NT_USERNAME=$2
NT_PWD=$3
LOG_DRIVE=$4
LOG_DIR=$5
WORK_DIR=/usr/local/groundwork/nagios/share/mssql

# Textfile listing the error text for which we will be scanning the errorlog.
TEXT_TO_FIND=/usr/local/groundwork/nagios/share/mssql/mssql_logfile_errstrings.txt

cd $WORK_DIR
smbclient //$SQL_HOST/$LOG_DRIVE $NT_PWD -U $NT_USERNAME -D $LOG_DIR -c "get ERRORLOG $SQL_HOST.ERRORLOG">/dev/null

if [ $? -ne 0 ]; then
	# smbclient returned an errorcode
	echo "SMB error while attempting to fetch errorlog.";
	exit 1;
fi

if [ ! -s "$SQL_HOST.ERRORLOG" ]; then
	# smbclient didn't return an errorcode, but the errorlog wasn't
	#  downloaded for some reason. Return an unknown status.
	echo "There was a problem retrieving the errorlog.";
	exit 1;
fi

# See how many lines are in the current errorlog.
NEW_LINE_COUNT=`cat $SQL_HOST.ERRORLOG|wc -l`

# Read in the number of lines that were in the errorlog the
#  last time we checked it. If we can't find how many were in the
#  log lasttime, rescan the whole log by setting OLD_LINE_COUNT to zero.
if [ -s "$SQL_HOST.ini" ]; then
	OLD_LINE_COUNT=`cat $SQL_HOST.ini`;
else
	OLD_LINE_COUNT=0;
fi


if [ $OLD_LINE_COUNT -gt $NEW_LINE_COUNT ]; then
	# Since the current logfile has less lines than the previous log,
	#  this means that this is a new logfile. The whole log should 
	#  be analyzed for errors.
	TAIL_LINE=$NEW_LINE_COUNT;
else
	if [ $OLD_LINE_COUNT -eq $NEW_LINE_COUNT ]; then
		# The logfile size has not changed since the last check.
		#  exitting without re-analyzing the logfile.	
		echo "OK. No new errors in SQL Server errorlog on $SQL_HOST";
		rm $SQL_HOST.ERRORLOG
		exit 0;
	else
		# The logfile has new entries since the last check. Check
		#  only the new entries.
		TAIL_LINE=`expr $NEW_LINE_COUNT - $OLD_LINE_COUNT`;
	fi
fi

# See how many lines were identified as having errors.
ERRORCOUNT=`tail -n $TAIL_LINE $SQL_HOST.ERRORLOG|grep -f $TEXT_TO_FIND|sed 's/^.\{10,10\} .\{11,11\} .\{2,9\} *//'|wc -l`

# Store the length of the errorlog in the ini file for that SQL HOST.
echo "$NEW_LINE_COUNT">$SQL_HOST.ini

# Remove the errorlog we downloaded
rm $SQL_HOST.ERRORLOG

# Set exit value and STDOUT.
if [ $ERRORCOUNT -gt 0 ]; then
	echo "$ERRORCOUNT new errors in the MSSQL errorlog on $SQL_HOST";
	exit 2;

elif [ $ERRORCOUNT -eq 0 ]; then
	echo "OK. No new errors in SQL Server errorlog on $SQL_HOST";
	exit 0;
fi 

