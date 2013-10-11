#!/bin/bash

OUTPUT=/tmp/nagios_debug.log

echo `date` $* >> $OUTPUT

# Command should be first argument
RESULT=`$* 2>&1`
EXITCODE=$?

(
echo $RESULT
echo "Exit code: $EXITCODE"
) | tee -a $OUTPUT

exit $EXITCODE

