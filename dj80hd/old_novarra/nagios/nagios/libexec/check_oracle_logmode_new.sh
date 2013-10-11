#!/bin/ksh

if [[ -z $1 ]]
then
   echo "usage: check_oracle_status <database name> <user> <password> <true/false>"
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
archive="$4"

errormessage=ERROR
errorlog=/tmp/$database.lgmerr.log
spoollog=/tmp/$database.lgmspl.log
outlog=/tmp/$database.lgmout.log

$ORACLE_HOME/bin/sqlplus $username/$password@$database>$errorlog<<EOF
set heading off
set pagesize 0
set linesize 100
set verify off
set echo off
spool $spoollog
select a.log_mode || ', autoarchive=' || b.value || '.' from  v\$database a, v\$parameter b where b.name = 'log_archive_start';
spool off
exit;
EOF

grep $errormessage $errorlog 1>/dev/null 2>&1

if [[ $? -eq 0 ]]
then
   echo "ERROR logging into database $db"
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 2
fi

egrep -v "and|^SQL>|mode|value|-----|from|select |order by|where" $spoollog >> $outlog

autoarch='Y'
archmode='Y'

txt=`cat $outlog`

grep "FALSE" $outlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   autoarch='N'
fi

grep "NOARCHIVELOG" $outlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   archmode='N'
fi

archsts=`echo ${archmode}${autoarch}`

if [ $archsts = "YY" ] && [ $4 = "true" ]
then
   echo  $txt
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 0
fi

if [ $archsts = "NN" ] && [ $4 = "false" ]
then
   echo  $txt
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 0
else
   echo  $txt
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 1
fi
