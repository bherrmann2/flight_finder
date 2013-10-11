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
errorlog=/tmp/$database.tsperr.log
spoollog=/tmp/$database.tspspl.log
outlog=/tmp/$database.tspout.log

$ORACLE_HOME/bin/sqlplus $username/$password@$database>$errorlog<<EOF
set heading off
set pagesize 0
set linesize 100
set verify off
set echo off
column Tablespace_Name format a15
column SPFREE format 999999.99
spool $spoollog
SELECT a.Tablespace_Name, 100*b.FBlocks/a.TBlocks AS SPFREE FROM (SELECT Tablespace_Name, SUM(Blocks) AS TBlocks FROM DBA_DATA_FILES GROUP BY Tablespace_Name) a, (SELECT Tablespace_Name,  SUM(Blocks) AS FBlocks FROM DBA_FREE_SPACE GROUP BY Tablespace_Name) b WHERE (a.Tablespace_Name = b.Tablespace_Name) and (100*b.FBlocks/a.TBlocks < 15);
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

egrep -v "and|^SQL>|Tablespace_Name|SPFREE|-----|from|select |order by|where" $spoollog >> $outlog

grep "no rows selected" $outlog 1>/dev/null 2>&1

if [[ $? -eq 0 ]]
then
   echo "No tablespaces full"
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 0
else
   echo "Some tablespaces > 85% full"
   rm $errorlog 2>/dev/null
   rm $spoollog 2>/dev/null
   rm $outlog 2>/dev/null
   exit 1
fi
