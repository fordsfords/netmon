#!/bin/sh
# netmon_sample.sh - force the "netmon.sh" daemon to take a data sample.
# See https://github.com/fordsfords/netmon for more information.

# This work is dedicated to the public domain under CC0 1.0 Universal:
# http://creativecommons.org/publicdomain/zero/1.0/
# 
# To the extent possible under law, Steven Ford has waived all copyright
# and related or neighboring rights to this work. In other words, you can 
# use this code for any purpose without any restrictions.
# This work is published from: United States.
# Project home: https://github.com/fordsfords/netmon

ARGSFILE="/tmp/netmon.args"
PIDFILE="/tmp/netmon.pid"

PID=""
if [ -f "$PIDFILE" ]; then :
  PID=`cat $PIDFILE`
else :
  echo "No PID file '$PIDFILE'"
  exit
fi

RUNNING=`ps auxw | sed -n "/netmon.sh/s/^[^ ][^ ]*  *\($PID\).*/\1/p"`
if [ "$RUNNING" = "$PID" ]; then :
  kill -USR1 $RUNNING
else :
  echo "PID $PID does not appear to be running; deleting $PIDFILE."
  rm $PIDFILE
  exit
fi
