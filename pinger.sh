#!/bin/sh
# monnet.sh

IP="$1"
if [ -z "$IP" ]; then :
  echo "pinger: Using 204.148.47.162 (verizon.com.customer.alter.net)"
  IP=204.148.47.162
fi

while true; do :
  ping -W 1 -n -c 1 $IP >/dev/null
  if [ $? -ne 0 ]; then echo "Gap `date`"; fi
done
