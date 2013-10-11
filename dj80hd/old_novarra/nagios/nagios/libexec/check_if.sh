#! /bin/sh 
#
# Usage: ./check_if --help
#
# Description: 
#	Used to verify speed and duplex settings via Nagios
#
# Output:
#	Outputs Critical Error if duplex is wrong, and Warning if speed is wrong.
#
# Notes:
#	Currently only supported on Solaris
#
#
# Examples: 
#	./check_if -i hme0 -s 100 -d full
#

# Paths to commands used in this script.  These
# may have to be modified to match your system setup.

# Added suport for Linux, check uname and if Linux use ethtool 
# July,27. Vladimir Novoselskiy  

PATH=""

ECHO="/bin/echo"
SED="/bin/sed"
ETHTOOL="/usr/sbin/ethtool"
GREP="/bin/grep"
DF="/bin/df"
DIFF="/bin/diff"
TAIL="/bin/tail"
CAT="/bin/cat"
RM="/bin/rm"
WC="/bin/wc"
METASTAT="/usr/sbin/metastat"

PROGNAME=`/bin/basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 0.1 $' | /bin/sed -e 's/[^0-9.]//g'`

. /usr/local/groundwork/nagios/libexec/utils.sh

print_usage() {
    echo "Usage: $PROGNAME -i <interface> -s <speed> -d <duplex>"
    echo "Usage: $PROGNAME --help"
    echo "Usage: $PROGNAME --version"
}

print_help() {
    print_revision $PROGNAME $REVISION
    echo ""
    print_usage
    echo ""
    echo "Check Interface Speed and Duplex"
    echo ""
    support
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 3 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

# Grab the command line arguments

exitstatus=$STATE_WARNING #default
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit $STATE_OK
            ;;
        -h)
            print_help
            exit $STATE_OK
            ;;
        --version)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        -V)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        -i)
	    INTERFACE=$2;
            shift;
            ;;
        -s)
	    CHECKSPEED=$2;
            shift;
            ;;
        -d)
	    CHECKDUPLEX=$2;
            shift;
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

# Only the root user can run the ndd commands
if [ "`/usr/bin/id | /usr/bin/cut -c1-5`" != "uid=0" ] ; then
   $ECHO "$INTERFACE UNKNOWN - You must be the root user to run `basename $0`."
   exit $STATE_UNKNOWN
fi

FOUND=0
# Determine the speed and duplex for each live NIC on the system
for INT_LIST in `/bin/netstat -i | /bin/egrep -v "^Name|^lo0" \
   | /usr/bin/awk '{print $1}' | /bin/sort | /usr/bin/uniq`
do
  if [ $INTERFACE = $INT_LIST ]; then
	FOUND=1
  fi
done


if [ $FOUND = 0 ]; then
  $ECHO "$INTERFACE Unknown - Interface not found"
  exit $STATE_UNKNOWN
fi


   # Special handling for "ce" interfaces
   if [ "`/bin/echo $INTERFACE \
   | /usr/bin/awk '/^ce[0-9]+/ { print }'`" ] ; then
      CE_INT_LINE_NO=`/usr/bin/kstat ce | /usr/bin/grep -n $INTERFACE \
         | /usr/bin/awk -F: '{print $1}'`
      CE_INT_DUPLEX_LINE_NO=`/usr/bin/expr $CE_INT_LINE_NO + 32`
      CE_INT_SPEED_LINE_NO=`/usr/bin/expr $CE_INT_LINE_NO + 34`
      DUPLEX=`/usr/bin/kstat ce | /usr/bin/awk 'NR == LINE { print $2 }' \
         LINE=$CE_INT_DUPLEX_LINE_NO`
      case "$DUPLEX" in
         1) DUPLEX="half" ;;
         2) DUPLEX="full" ;;
      esac
      SPEED=`/usr/bin/kstat ce | /usr/bin/awk 'NR == LINE { print $2 }' \
         LINE=$CE_INT_SPEED_LINE_NO`
      case "$SPEED" in
         10) SPEED="10" ;;
         100) SPEED="100" ;;
         1000) SPEED="1000" ;;
      esac 
   # Special handling for "bge" interfaces
   elif [ "`/bin/echo $INTERFACE \
   | /usr/bin/awk '/^bge[0-9]+/ { print }'`" ] ; then
      BGE_INT_LINE_NO=`/usr/bin/kstat bge | /usr/bin/grep -n $INTERFACE \
         | /usr/bin/awk -F: '{print $1}'`
      BGE_INT_DUPLEX_LINE_NO=`/usr/bin/expr $BGE_INT_LINE_NO + 9`
      BGE_INT_SPEED_LINE_NO=`/usr/bin/expr $BGE_INT_LINE_NO + 14`
      DUPLEX=`/usr/bin/kstat bge | /usr/bin/awk 'NR == LINE { print $2 }' \
         LINE=$BGE_INT_DUPLEX_LINE_NO`
      SPEED=`/usr/bin/kstat bge | /usr/bin/awk 'NR == LINE { print $2 }' \
         LINE=$BGE_INT_SPEED_LINE_NO`
      case "$SPEED" in
         10000000) SPEED="10" ;;
         100000000) SPEED="100" ;;
         1000000000) SPEED="1000" ;;
      esac 
   # All other interfaces
   else
      INTERFACE_TYPE=`/bin/echo $INTERFACE | /bin/sed -e "s/[0-9]*$//"`
      INSTANCE=`/bin/echo $INTERFACE | /bin/sed -e "s/^[a-z]*//"`
	UNAME=$(/bin/uname)
	if [ "$UNAME" != "Linux" ]; then 
      	/usr/sbin/ndd -set /dev/$INTERFACE_TYPE instance $INSTANCE
   	SPEED=`/usr/sbin/ndd -get /dev/$INTERFACE_TYPE link_speed`
	fi
SPEED=$($ETHTOOL $INTERFACE|$GREP Speed|$SED 's/Speed://'|$SED 's/^[ \t]*//'|$SED 's/Mb//'|$SED 's/\/s//')
      case "$SPEED" in
         0) SPEED="10" ;;
         1) SPEED="100" ;;
         1000) SPEED="1000" ;;
      esac
	DUPLEX=$($ETHTOOL $INTERFACE|$GREP Duplex|$SED 's/Duplex://'|$SED 's/^[ \t]*//')
      case "$DUPLEX" in
         0) DUPLEX="Half" ;;
         1) DUPLEX="Full" ;;
         *) DUPLEX="" ;;
      esac

   fi


if [ "$($ETHTOOL $INTERFACE|$GREP Duplex|$SED 's/Duplex://'|$SED 's/^[ \t]*//')" != "$CHECKDUPLEX" ]; then
   $ECHO "$INTERFACE CRITICAL - Speed=$SPEED, Duplex=$($ETHTOOL $INTERFACE|$GREP Duplex|$SED 's/Duplex://'|$SED 's/^[ \t]*//')"
    exit $STATE_CRITICAL
fi

if [ "$SPEED" != "$CHECKSPEED" ]; then
    $ECHO "$INTERFACE WARNING - Speed=$SPEED, Duplex=$($ETHTOOL $INTERFACE|$GREP Duplex|$SED 's/Duplex://'|$SED 's/^[ \t]*//')"
    exit $STATE_WARNING
fi
    $ECHO "$INTERFACE OK - Speed=$SPEED, Duplex=$($ETHTOOL $INTERFACE|$GREP Duplex|$SED 's/Duplex://'|$SED 's/^[ \t]*//')"
exit $STATE_OK

