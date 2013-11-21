#!/bin/ksh


if [[ -z $1 ]]
then
   echo "usage: check_oracle_status <database name> <user> <password>"
   exit 1
fi

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/8.1.7
export LD_ASSUME_KERNEL=2.2.5
export NLS_LANG=AMERICAN_AMERICA.UTF8
export ORA_NLS33=$ORACLE_HOME/ocommon/nls/admin/data
export PATH=$PATH:/usr/local/bin:/bin:$ORACLE_HOME/bin

database="$1"
username="$2"
password="$3"

errorlog=/tmp/$database.error.log

errormessage=ERROR

$ORACLE_HOME/bin/sqlplus $username/$password@$database>$errorlog<<EOF
quit
EOF

grep $errormessage $errorlog 1>/dev/null 2>&1
exitcode=$?

if [ $exitcode = 0 ]
	then
	echo "Unable to connect to database: $database"
	rm $errorlog 2>/dev/null
	exit 2
	else
		if [ $exitcode = 1 ]
		then
		echo "Connected to database: $database"
		rm $errorlog 2>/dev/null
		exit 0
		else
			echo "Unknown error connecting to database: $database"
fi
fi

