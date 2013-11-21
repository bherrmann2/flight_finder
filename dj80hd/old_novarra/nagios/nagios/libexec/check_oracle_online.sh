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

errormessage=ERROR
errorlog=/tmp/$database.online.log
spoollog=/tmp/$database.spool.log
outlog=/tmp/$database.out.log

$ORACLE_HOME/bin/sqlplus $username/$password@$database>$errorlog<<EOF
set heading off
set pagesize 0
set linesize 100
set verify off
set echo off
column file_name       format a30
column tablespace_name format a8
spool $spoollog
select distinct f.tablespace_name, b.status
from   dba_data_files f, v\$backup b
where  b.status != 'NOT ACTIVE'
and    f.file_id = b.file#
order by f.tablespace_name;
spool off
quit;
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

egrep -v "and|^SQL>|TABLESPACE_NAME|STATUS|-----|from|select |order by|where" $spoollog >> $outlog

grep "no rows selected" $outlog 1>/dev/null 2>&1

if [[ $? -eq 0 ]]
then
   echo "No tablespaces offline"
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 0
fi
   
grep "ACTIVE" $outlog 1>/dev/null 2>&1
if [[ $? -eq 0 ]]
then
   echo "Database $1 being backed up."
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 0
else
   cat $outlog
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 2
fi

