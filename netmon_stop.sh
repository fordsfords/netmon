#!/bin/sh
# netmon_stop.sh - stop the "netmon.sh" daemon.

# This code and its documentation is Copyright 2022-2023 Steven Ford
# and licensed "public domain" style under Creative Commons "CC0":
#   http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/netmon

# See https://github.com/fordsfords/netmon for more information.


ARGSFILE="/tmp/netmon.args"
PIDFILE="/tmp/netmon.pid"

if [ -f "$ARGSFILE" ]; then :
  if mv "$ARGSFILE" "$ARGSFILE.stopped"; then :
  else :
    echo "Could not rename $ARGSFILE to $ARGSFILE.stopped; continuing..."
  fi
else :
  echo "No $ARGSFILE?"
fi

PID=""
if [ -f "$PIDFILE" ]; then :
  PID=`cat $PIDFILE`
else :
  echo "No PID file '$PIDFILE'"
  exit
fi

RUNNING=`ps auxw | sed -n "/netmon.sh/s/^[^ ][^ ]*  *\($PID\).*/\1/p"`
if [ "$RUNNING" = "$PID" ]; then :
  kill $RUNNING
else :
  echo "PID $PID does not appear to be running; deleting $PIDFILE."
  rm $PIDFILE
  exit
fi

sleep 2

STILL_RUNNING=`ps auxw | sed -n "/netmon.sh/s/^[^ ][^ ]*  *\($PID\).*/\1/p"`
if [ "$STILL_RUNNING" = "$PID" ]; then :
  echo "ERROR: Tried to kill PID $PID, but it's still running"
  exit 1
fi

rm $PIDFILE
