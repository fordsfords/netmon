#!/bin/sh
# netmon.sh - Monitor various network stats
# This code and its documentation is Copyright 2022-2023 Steven Ford
# and licensed "public domain" style under Creative Commons "CC0":
#   http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/netmon

# See https://github.com/fordsfords/netmon for more information.

cd /  # Release working dir (good practice).

WARNINGS=""

PIDFILE="/tmp/netmon.pid"
if echo "$$" >$PIDFILE; then :
else :
  echo "ERROR: could not write to $PIDFILE" >&2
  exit 1
fi

usage() {
  cat <<__EOF__ 1>&2
Usage: netmon.sh [-h] [-i intfcs] ... [-l logfile] [-p prefix] [-s seconds]
Where:
  -h help
  -i intfcs - interfaces for ethtool. Default: "*" (all running non-loopback).
              If multiple interfaces, space-separate and enclose in quotes.
              E.g. -i "en0 en1".
  -l logfile - Log file path (no day of week appended).
  -p prefix - Prefix path, appended with day of week; default: /tmp/netmon.log
  -s seconds - Seconds to wait between samples; default: 600 (10 min)
See https://github.com/fordsfords/netmon for more information.
__EOF__
  exit 1
}  # usage


# Figure out the current log file name. Call for every loop.
# On a midnight crossing, the log file name will change.
setlog() {
  PREV_LOG="$LOG"
  if [ -n "$LOGFILE" ]; then :
    # -l logfile overrides all.
    LOG="$LOGFILE"
  else :
    # Set the daily log file name and delete it if it's last week's.
    LOG="$PREFIX.`date +%a`"  # Append 3-letter day of week to log file prefix.
    if MODTIME=`date -r $LOG +%s 2>/dev/null`; then :
      NOWTIME=`date +%s`
      LOG_AGE=`expr $NOWTIME - $MODTIME`
      if [ $LOG_AGE -gt 518400 ]; then :  # more than 6 days old?
        rm -f $LOG
      fi
    fi
  fi
  if [ "$PREV_LOG" != "$LOG" ]; then :
    # Either this is the first time running, or it's after midnight.
    # Record basic system information.
    if echo "Starting $LOG on `hostname`, date=`date`" >>$LOG; then :
    else :
      echo "ERROR: could not write to $LOG" >&2
      exit 1
    fi

    echo "" >>$LOG; echo "netmon: INTFCS='$INTFCS', LOGFILE='$LOGFILE', PREFIX='$PREFIX', SECS='$SECS'" >>$LOG
    if [ -n "$WARNINGS" ]; then echo "$WARNINGS"  >>$LOG; fi
    echo "" >>$LOG; echo "uname -r" >>$LOG; uname -r >>$LOG 2>&1
    echo "" >>$LOG; echo "cat /etc/os-release" >>$LOG; cat /etc/os-release >>$LOG 2>&1
    echo "" >>$LOG; echo "uptime" >>$LOG; uptime >>$LOG 2>&1
    echo "" >>$LOG; echo "sysctl net.core.rmem_max" >>$LOG; sysctl net.core.rmem_max >>$LOG 2>&1
    echo "" >>$LOG; echo "lscpu" >>$LOG; lscpu >>$LOG 2>&1
  fi
}  # setlog


# Function to print a sample.
sample () {
  if echo "" >>$LOG; echo "date=`date`" >>$LOG; then :
  else :
    echo "ERROR: could not write to $LOG" >&2
    exit 1
  fi

  echo "" >>$LOG; echo "netstat -g -n" >>$LOG; netstat -g -n >>$LOG 2>&1
  echo "end netstat -g -n" >>$LOG

  if [ -n "$GOOD_INTFCS" ]; then :
    for I in $GOOD_INTFCS; do :
      echo "" >>$LOG; echo "ethtool -S $I" >>$LOG; ethtool -S $I >>$LOG 2>&1
      echo "end ethtool -S $I" >>$LOG
    done
  else :
    echo "" >>$LOG; echo "No valid interfaces supplied for ethtool" >>$LOG
  fi

  if [ -n "$SFREPORT" ]; then :
    echo "" >>$LOG; echo "perl $SFREPORT -" >>$LOG; perl $SFREPORT - >>$LOG 2>&1
    echo "end perl $SFREPORT -" >>$LOG
  fi

  if [ $STACKDUMP -eq 1 ]; then :
    echo "" >>$LOG; echo "onload_stackdump lots" >>$LOG; onload_stackdump lots >>$LOG 2>&1
    echo "end onload_stackdump lots" >>$LOG
  fi

  echo "" >>$LOG; echo "ifconfig" >>$LOG; ifconfig >>$LOG 2>&1
  echo "end ifconfig" >>$LOG

  echo "" >>$LOG; echo "netstat -s" >>$LOG; netstat -s >>$LOG 2>&1
  echo "end netstat -s" >>$LOG
}  # sample


# Set defaults.
INTFCS="$NETMON_INTFCS"
if [ -z "$INTFCS" ]; then :
  INTFCS="$NETMON_INTFC"  # backward compatibility
fi
if [ -z "$INTFCS" ]; then :
  if [ -f /tmp/netmon.intfc ]; then :
    INTFCS=`cat /tmp/netmon.intfc`
  fi
fi
if [ -z "$INTFCS" ]; then :
  INTFCS="*"
fi
LOGFILE="$NETMON_LOGFILE"
PREFIX="$NETMON_PREFIX"
if [ -z "$PREFIX" ]; then :
  PREFIX="/tmp/netmon.log"
fi
SECS="$NETMON_SECS"
if [ -z "$SECS" ]; then :
  SECS=600  # Sleep for 10 minutes between samples.
fi

# Get command-line options.
while getopts "hi:l:p:s:" OPTION
do
  case $OPTION in
    h) usage ;;
    i) INTFCS="$OPTARG" ;;
    l) LOGFILE="$OPTARG" ;;
    p) PREFIX="$OPTARG" ;;
    s) SECS="$OPTARG" ;;
    \?) usage ;;
  esac
done
shift `expr $OPTIND - 1`  # Make $1 the first positional param after options
if [ -n "$1" ]; then echo "Error, unrecognized positional parameter '$1'" >&2; exit 1; fi

# All interfaces?
if [ "$INTFCS" = "*" ]; then :
  INTFCS=`ifconfig | sed -n '/^lo:/d;/RUNNING/s/^\([a-zA-Z0-9][^:]*\):.*RUNNING.*/\1/p'`
fi

# Use only the interfaces that work with ethtool.
GOOD_INTFCS=""
if [ -n "$INTFCS" ]; then :
  for I in $INTFCS; do :
    if ethtool -S $I >/dev/null; then :
      GOOD_INTFCS="$GOOD_INTFCS $I"
    else :
      WARNINGS="$WARNINGS
Warning: 'ethtool -S $I' doesn't work; skipping interface"
    fi
  done
fi

if onload_stackdump >/dev/null 2>&1; then :
  STACKDUMP=1
else :
  STACKDUMP=0
  WARNINGS="$WARNINGS
Warning: onload_stackdump not present or returns bad status"
fi

# If sfreport.pl not in PATH, SFREPORT will be empty.
SFREPORT="`which sfreport.pl 2>/dev/null`"
if [ -z "$SFREPORT" ]; then :
  WARNINGS="$WARNINGS
Warning: sfreport.pl not found in PATH"
fi

LOG=""

RUNNING=1
trap "RUNNING=0" HUP INT QUIT TERM
SAMPLE=0
trap "SAMPLE=1" USR1

NOW_SECS=`date +%s`
END_SECS=`expr $NOW_SECS + $SECS`
while [ "$RUNNING" -eq 1 ]; do :
  setlog
  sample

  echo "" >>$LOG; echo "Waiting for $SECS seconds" >>$LOG
  while [ "$RUNNING" -eq 1 -a `date +%s` -lt "$END_SECS" ]; do :
    sleep 1
    if [ "$SAMPLE" -eq 1 ]; then :
      echo "" >>$LOG; echo "USR1 sample" >>$LOG
      sample
      SAMPLE=0
    fi
  done

  END_SECS=`expr $END_SECS + $SECS`
done

echo "" >>$LOG; echo "Final sample" >>$LOG
sample  # One more sample before exit.

exit 0
