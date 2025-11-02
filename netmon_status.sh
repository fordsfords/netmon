#!/bin/sh
# netmon_status.sh - tells you if netmon is running or not.
# See https://github.com/fordsfords/netmon for more information.

# This work is dedicated to the public domain under CC0 1.0 Universal:
# http://creativecommons.org/publicdomain/zero/1.0/
# 
# To the extent possible under law, Steven Ford has waived all copyright
# and related or neighboring rights to this work. In other words, you can 
# use this code for any purpose without any restrictions.
# This work is published from: United States.
# Project home: https://github.com/fordsfords/netmon

TOOLDIR="`dirname ${BASH_SOURCE[0]}`"
ARGSFILE="/tmp/netmon.args"
PIDFILE="/tmp/netmon.pid"
LOGFILE="/tmp/netmon.log"  # This file won't be used unless there are errors.

STATUS=0
PID=""
if [ -f "$PIDFILE" ]; then :
  if [ ! -f "$ARGSFILE" ]; then :
    echo "Warning: $PIDFILE exists but $ARGSFILE not."
    STATUS=1
  fi
  PID=`cat $PIDFILE`
  RUNNING=`ps auxw | sed -n "/netmon.sh/s/^[^ ][^ ]*  *\($PID\).*/\1/p"`
  if [ "$RUNNING" = "$PID" ]; then :
    echo "netmon is running with PID $PID."
    echo "Options:"; cat "$ARGSFILE"
    exit $STATUS
  fi
  echo "Warning: PID $PID does not appear to be running, but $PIDFILE thinks it should be."
  STATUS=1
  exit $STATUS
fi

if [ -f "$ARGSFILE" ]; then :
  echo "Warning: $PIDFILE does not exist but $ARGSFILE does."
  STATUS=1
fi

echo "netmon not running."
if [ -f "$ARGSFILE.stopped" ]; then :
  echo "Options:"; cat "$ARGSFILE.stopped"
fi
