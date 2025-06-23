#!/bin/sh
# monnet.sh

while true; do :
  ping -W 1 -n -c 1 74.6.143.26 >/dev/null
  if [ $? -ne 0 ]; then echo "Gap `date`"; fi
done
