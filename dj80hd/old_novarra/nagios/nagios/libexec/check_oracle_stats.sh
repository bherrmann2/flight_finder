#!/bin/ksh

if [[ -z $1 ]]
then
   echo "usage: check_oracle_stats <database name> <statno>"
   exit 0
fi

database="$1"
statps=`expr "$2" + 4 `

case $2 in
01)
#         "Buffer Quality %"
   stattx=" (> 94 %)"
   ;;
02)
#         "SQL get ratio %"
   stattx=" (> 90 %)"
   ;;
03)
#         "SQL pin ratio %"
   stattx=" (> 90 %)"
   ;;
04)
#         "Dictionary quality %"
   stattx=" (> 90 %)"
   ;;
05)
#         "Sorts memory/disk %"
   stattx=" (< 1 %)"
   ;;
06)
#         "User calls/Recursive calls"
   stattx=" (> 5)"
   ;;
07)
#         "Reads/User Calls"
   stattx=" (< 30)"
   ;;
08)
#         "Rollback segment waits %"
   stattx=" (< 1 %)"
   ;;
09)
#         "Sequential reads time in ms"
   stattx=" (< 20 ms)"
   ;;
10)
#         "Scattered reads time in ms"
   stattx=" (< 20 ms)"
   ;;
11)
#         "Log file sync time in ms"
   stattx=" (< 20 ms)"
   ;;
12)
#         "Buffer waits time in ms"
   stattx=" (< 20 ms)"
   ;;
13)
#         "Avg Read time per block in ms"
   stattx=" (< 20 ms)"
   ;;
14)
#         "Avg write time per block in ms"
   stattx=" (< 20 ms)"
   ;;
esac

cd /tmp/$1
if [[ $? -ne 0 ]]
then
   echo "Statistics collection not active"
   exit 2
fi

if test -f db_stats.txt
then
   statvl=`cat db_stats.txt | tail -1|cut -f${statps} -d,`
   echo $statvl $stattx
   option=`expr $statps - 4 `
   value=`echo $statvl|cut -f1 -d.` 
   if [[ $value = "" ]]
   then 
    value=0
   fi
#  echo $option $value

   if test $option -eq 1 
   then
   if test $value -lt 94 
     then
#      echo 1 Warning
       exit 0
     else
#      echo 1 Good
       exit 0
   fi
   fi
   if test $option -eq 2 
   then   
   if test $value -lt 90 
     then
#      echo 2 Warning
       exit 0
     else
#      echo 2 Good
       exit 0
   fi
   fi
   if test $option -eq 3
   then 
   if test $value -lt 90
     then
#      echo 3 Warning
       exit 0
     else
#      echo 3 Good
       exit 0
   fi
   fi
   if test $option -eq 4
   then
   if test $value -lt 90
     then
#      echo 4 Warning
       exit 0
     else
#      echo 4 Good
       exit 0
   fi
   fi
   if test $option -eq 5
   then
   if test $value -gt 1
     then
#      echo 5 Warning
       exit 0
     else
#      echo 5 Good
       exit 0
   fi
   fi
   if test $option -eq 6 
   then
   if test $value -lt 5 
        then
#         echo 6 Warning
          exit 0
        else
#         echo 6 Good
          exit 0
   fi
   fi
   if test $option -eq 7
   then
   if test $value -gt 30
     then
#      echo 7 Warning
       exit 0
     else
#      echo 7 Good
       exit 0
   fi
   fi
   if test $option -eq 8
   then
   if test $value -gt 1
     then
#      echo 8 Warning
       exit 0
     else
#      echo 8 Good
       exit 0
   fi
   fi
   if test $option -eq 9
   then
   if test $value -gt 20
     then
#      echo 9 Warning
       exit 0
     else
#      echo 9 Good
       exit 0
   fi
   fi
   if test $option -eq 10
   then
   if test $value -gt 20
     then
#      echo 10 Warning
       exit 0
     else
#      echo 10 Good
       exit 0
   fi
   fi
   if test $option -eq 11
   then
   if test $value -gt 20
     then
#      echo 11 Warning
       exit 0
     else
#      echo 11 Good
       exit 0
   fi
   fi
   if test $option -eq 12
   then
   if test $value -gt 20
     then
#      echo 12 Warning
       exit 0
     else
#      echo 12 Good
       exit 0
   fi
   fi
   if test $option -eq 13
   then 
   if test $value -gt 20
     then
#      echo 13 Warning
       exit 0
     else
#      echo 13 Good
       exit 0
   fi
   fi
   if test $option -eq 14
   then
   if test $value -gt 20
     then
#      echo 14 Warning
       exit 0
     else
#      echo 14 Good
       exit 0
   fi
   fi
else
   echo "Statistics collection not active"
   exit 2
fi
