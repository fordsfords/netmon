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


usage() {
  cat <<__EOF__ 1>&2
Usage: netmon.sh [-h] [-i intfc] [-l logfile] [-p prefix] [-s seconds]
Where:
  -h help
  -i intfc - interface for ethtool; default: /tmp/netmon.intfc
  -l logfile - Log file path (no day of week appended).
  -p prefix - Prefix path, appended with day of week; default: /tmp/netmon.log
  -s seconds - Seconds to wait between samples; default: 600 (10 min)
See https://github.com/fordsfords/netmon for more information.
__EOF__
  exit 1
}  # usage


setlog() {
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
}  # setlog


# Function to print a sample.
sample () {
  echo "" >>$LOG; echo "date=`date`" >>$LOG
  echo "" >>$LOG; echo "netstat -g -n" >>$LOG; netstat -g -n >>$LOG 2>&1
  if [ -n "$INTFC" ]; then :
    echo "" >>$LOG; echo "ethtool -S $INTFC" >>$LOG; ethtool -S $INTFC >>$LOG 2>&1
  fi
  if [ $ONLOAD -eq 1 ]; then :
    echo "" >>$LOG; echo "onload_stackdump lots" >>$LOG; onload_stackdump lots >>$LOG 2>&1
  fi
  echo "" >>$LOG; echo "ifconfig" >>$LOG; ifconfig >>$LOG 2>&1
  echo "" >>$LOG; echo "netstat -us" >>$LOG; netstat -us >>$LOG 2>&1
}  # sample


# Set defaults.
INTFC="$NETMON_INTFC"
if [ -z "$INTFC" ]; then :
  if [ -f /tmp/netmon.intfc ]; then :
    INTFC=`cat /tmp/netmon.intfc`
  fi
fi
LOGFILE="$NETMON_LOGFILE"
PREFIX="$NETMON_PREFIX"
if [ -z "$PREFIX" ]; then :
  PREFIX="/tmp/netmon.log"
fi
SECONDS="$NETMON_SECONDS"
if [ -z "$SECONDS" ]; then :
  SECONDS=600  # Sleep for 10 minutes between samples.
fi

# Get command-line options.
while getopts "hi:l:p:s:" OPTION
do
  case $OPTION in
    h) usage ;;
    i) INTFC="$OPTARG" ;;
    l) LOGFILE="$OPTARG" ;;
    p) PREFIX="$OPTARG" ;;
    s) SECONDS="$OPTARG" ;;
    \?) usage ;;
  esac
done
shift `expr $OPTIND - 1`  # Make $1 the first positional param after options

if [ -n "$INTFC" ]; then :
  if ethtool -S $I >/dev/null; then :
  else :
    echo "Warning, 'ethtool $INTFC' doesn't work; skipping ethtool"
    INTFC=""
  fi
else :
  echo "Skipping ethtool"
fi

if onload_stackdump >/dev/null 2>&1; then :
  ONLOAD=1
else :
  echo "Onload_stackdump not working"
  ONLOAD=0
fi

setlog
if [ -n "$LOGFILE" ]; then :
  cat /dev/null >$LOG
fi

echo "Starting netmon.sh on `hostname`, date=`date`" >>$LOG

echo "" >>$LOG; echo "uname -r" >>$LOG; uname -r >>$LOG 2>&1
echo "" >>$LOG; echo "cat /etc/os-release" >>$LOG; cat /etc/os-release >>$LOG 2>&1
echo "" >>$LOG; echo "uptime" >>$LOG; uptime >>$LOG 2>&1
echo "" >>$LOG; echo "sysctl net.core.rmem_max" >>$LOG; sysctl net.core.rmem_max >>$LOG 2>&1
echo "" >>$LOG; echo "lscpu" >>$LOG; lscpu >>$LOG 2>&1

RUNNING=1
trap "RUNNING=0" 1 2 3 15

while [ "$RUNNING" -eq 1 ]; do :
  sample

  echo "" >>$LOG; echo "Waiting for $SECONDS seconds" >>$LOG
  END_SECONDS=`date +%s`; END_SECONDS=`expr $END_SECONDS + $SECONDS`
  while [ "$RUNNING" -eq 1 -a `date +%s` -lt "$END_SECONDS" ]; do sleep 1; done

  setlog
done

echo "" >>$LOG; echo "Final sample" >>$LOG
sample  # One more sample before exit.

exit 0
