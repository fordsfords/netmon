# netmon

Monitoring script for hosts running UDP-intensive applications.

# Table of contents
<!-- mdtoc-start -->
&DoubleRightArrow; [netmon](#netmon)  
&DoubleRightArrow; [Table of contents](#table-of-contents)  
&DoubleRightArrow; [Introduction](#introduction)  
&nbsp;&nbsp;&DoubleRightArrow; [Impact](#impact)  
&DoubleRightArrow; [Usage:](#usage)  
&nbsp;&nbsp;&DoubleRightArrow; [netmon.sh](#netmonsh)  
&nbsp;&nbsp;&DoubleRightArrow; [netmon_start.sh](#netmonstartsh)  
&nbsp;&nbsp;&DoubleRightArrow; [netmon_check.sh](#netmonchecksh)  
&nbsp;&nbsp;&DoubleRightArrow; [netmon_sample.sh](#netmonsamplesh)  
&nbsp;&nbsp;&DoubleRightArrow; [netmon_stop.sh](#netmonstopsh)  
&DoubleRightArrow; [Design](#design)  
&nbsp;&nbsp;&DoubleRightArrow; [Interpretation of Data](#interpretation-of-data)  
&nbsp;&nbsp;&nbsp;&nbsp;&DoubleRightArrow; [Nodesc Drops](#nodesc-drops)  
&nbsp;&nbsp;&nbsp;&nbsp;&DoubleRightArrow; [Onload Oflow Drops](#onload-oflow-drops)  
&nbsp;&nbsp;&nbsp;&nbsp;&DoubleRightArrow; [Onload Mem Drops](#onload-mem-drops)  
&nbsp;&nbsp;&nbsp;&nbsp;&DoubleRightArrow; [UDP Receive Errors](#udp-receive-errors)  
&DoubleRightArrow; [Configuration](#configuration)  
&DoubleRightArrow; [Log File: Rolling](#log-file-rolling)  
&DoubleRightArrow; [Log File: Fixed](#log-file-fixed)  
&DoubleRightArrow; [Graceful Exit](#graceful-exit)  
&DoubleRightArrow; [License](#license)  
<!-- TOC created by '../mdtoc/mdtoc.pl README.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

# Introduction

Over the years, I've had many occasions where a network-intensive application
had problems, and I've wanted information about the system on which it
is running. Things like "netstat", "ethtool -S', and if Onload is being used,
"onload_stackdump lots" and "sfreport.pl".
Typically I just create an ad-hoc script that wakes
up every few minutes and runs the commands.

More recently, I've been working with a customer
and have made various improvements to my ad-hoc script,
and decided it deserved a repository.
I'm sure there are much better monitoring tools out there
that generate pretty reports with fancy graphs,
but this is better than nothing.
(And "nothing" is what most people do.)

## Impact

One concern that many people have regarding monitoring tools is how much
the act of monitoring affects the system being monitored.
In particular, customers are worried about network monitoring introducing
message latency and possibly even causing packet loss.

I am not an expert in these matters.
For example, I do not know how invasive "ethtool -S" is.
Same with "onload_stackdump".
I have spoken with a Solarflare engineer who has assured me that
the monitoring tools used by this repo have insignificant impact.
I was advised against trying to run them multiple times per second,
but that running them every few minutes would be fine.
Given that Solarflare's customers are typically VERY concerned about latency,
I am inclined to trust Solarflare's judgment in this matter.

But since my information is second-hand,
I cannot certify claims of "insignificant impact".

That said, the diagnostic value of doing this kind of minitoring is high.
You can't decide to turn it on after you notice a network problem;
most of the counters sampled here are cumulative.
You need "before" and "after" samples.
If you're worried about the impact of these tools,
configure it to run once an hour.
You won't get good granulatiry,
but hourly data is infinitely better than no data.
(And see [netmon_sample.sh](#netmon_samplesh).)

# Usage:

Some people have the attitude that they start monitoring tools running
the moment they detect a bad behavior.

This approach is barely useful.

Most of the tools exercised by "netmon" have cumulative counters,
so you need a sample of the counters both before and after the incident.
Since you probably can't predict when an incident will happen,
the best approach is to leave the tool running continuously on all
hosts that run network-intensive applications.

The tool is designed to roll the log file by day of week,
so you won't have an infinitely-growing log file that requires
periodic purging.

## netmon.sh

Here's the help from the netmon.sh tool:
````
Usage: netmon.sh [-h] [-i intfc] [-l logfile] [-p prefix] [-s seconds]
Where:
  -h help
  -i intfcs - interfaces for ethtool. Default: "*" (all running non-loopback).
              If multiple interfaces, space-separate and enclose in quotes.
              E.g. -i "en0 en1".
  -l logfile - Log file path (fixed path, no day of week appended).
  -p prefix - Prefix path, appended with day of week. Default: "/tmp/netmon.log"
  -s seconds - Seconds to wait between samples. Default: 600 (10 min)
See https://github.com/fordsfords/netmon for more information.
````

## netmon_start.sh

To assist in running the tool continuously,
there is a "netmon_start.sh" script that starts the monitoring
script as a daemon (e.g. you can log out and the daemon will continue
running).

The "netmon_start.sh" tool also records the desired command-line parameters
of "netmon.sh" so that it can be restarted easily with the same settings.
Those command-line parameters must be enclosed in single quotes.

For example:

````
$ ./netmon_start.sh '-s 300 -i "en0 en1"'
````

This records the netmon options in "/tmp/netmon.args".
Subsequently, you can stop and restart the tool without options
and it will re-use the saved ones.
For example:

`````
$ ./netmon_start.sh '-s 300'
$ ./netmon_stop.sh
$ ./netmon_start.sh
Using /tmp/netmon.args.stopped
`````

## netmon_check.sh

The "netmon_check.sh" script is intended to be run
periodically (perhaps hourly) as a cron job.
It checks to see if netmon should be running and restarts it if needed.
This is useful after a system reboot.

No command-line parameters are permitted.

````
$ ./netmon_start.sh '-s 300'
$ kill -9 `cat /tmp/netmon.pid`  # abnormally stop
$ ./netmon_check.sh
````
The netmon check restarts the abnormally killed daemon.

## netmon_sample.sh

The "netmon_sample.sh" script tells the netmon daemon to
generate an extra sample (using the USR1 signal).
This can be useful if the daemon was configured to run infrequently,
and you notice a network-related incident.
Generating extra samples can give more-timely information.

No command-line parameters are permitted.

````
$ ./netmon_sample.sh
````

Note that it might take a second for netmon to respond.

## netmon_stop.sh

The "netmon_stop.sh" script not only stops the daemon,
but also prevents the "netmon_check.sh" script from restarting it
by renaming "/tmp/netmon.args" to "/tmp/netmon.args.stopped".

No command-line parameters are permitted.

````
$ ./netmon_stop.sh
````

Note that it might take a second for netmon to respond.

# Design

netmon.sh is intended to be run in the background.
As it is writing to a log file, it records the following information:
* uname -r
* cat /etc/os-release
* uptime
* sysctl net.core.rmem_max
* lscpu

Then, it loops periodically, recording a "sample" consisting of:
* netstat -g -n
* ethtool -S <interface>
* onload_stackdump lots
* sfreport -
* ifconfig
* netstat -us

Note that if the tool detects that ethtool, onload_stackdump,
or sfreport.pl don't work, it skips that non-working command(s).
For example, if a host doesn't have Onload, the "onload_stackdump"
and "sfreport.pl" are skipped.
(You can also have a situation where "onload_stackdump" works but
"sfreport.pl" is not present in PATH.
You can download "sfreport.pl" util from the customer support site at:
https://www.xilinx.com/support/download/nic-software-and-drivers.html#drivers-software
Then under Linux, click on "Solarflare Linux diagnostics (sfreport)".
As of May, 2023, the download file is
"SF-108317-LS-7-Solarflare-Linux-diagnostic-sfreport.tgz";
be aware that contrary to the file extension, it is NOT a zipped tar file.
It is just a tar file containing "sfreport.pl".
It should be untarred and placed in a location in root's PATH.)

## Interpretation of Data

It is beyond the scope of this repository to teach you how to diagnose a wide
variety of network problems using the output of netmon.
For Solarflare-specific output (onload_stackdump, sfreport, ethtool)
I recommend contacting Solarflare support directly.

That said, here are some specific things I often look for:

### Nodesc Drops

````
port_rx_nodesc_drops: 946553
````
This is part of "ethtool" output for Solarflare NICs and is short
for "no (receive) descriptor drops".
It indicates that packets are arriving faster than the driver can
process them.
The NIC has a limited number of receive descriptors that hold
received packets until the driver can retrieve them.

If you are getting nodesc drops, the first thing to do is ensure
that you configure the NIC for the maximum number of receive descriptors,
which is 4096 for all versions of the NIC that I'm familiar with.

### Onload Oflow Drops

````
  rcv: oflow_drop=0(0%) mem_drop=700 eagain=0 pktinfo=0 q_max_pkts=99
````
This is part of "onload_stackdump lots" output for Solarflare NICs
being used with Onload.
It indicates socket buffer overflow.

Either this application needs to handle incoming messages faster,
or you need to increase the size of the socket buffer.

### Onload Mem Drops

````
  rcv: oflow_drop=0(0%) mem_drop=700 eagain=0 pktinfo=0 q_max_pkts=99
````
This is part of "onload_stackdump lots" output for Solarflare NICs
being used with Onload.
It usually indicates that too much memory is being held in non-empty
socket buffers.

Either the applications on this host need to handle collectively
incoming messages faster,
or you need to increase the amount of memory available to Onload.

### UDP Receive Errors

````
Udp:
    ...
    0 packet receive errors
````
This is part of "netstat -us" output and usually indicates socket buffer
overflow.
Note that sockets that are accelerated using Onload do NOT update
this counter.
This is for applications running without Onload.

Note that the output of "netstat -us" can vary with the version of Linux.
Here's another possible output:
````
Udp:
    ...
    0 receive buffer errors
````

Either this application needs to handle incoming messages faster,
or you need to increase the size of the socket buffer.

# Configuration

The tool can be configured via command-line options
or with environment variables.
If both are supplied, the command-line options have priority.

Item | Command-line Option | Environment Variable
---- | ------------------- | --------------------
Network Interfaces | -i intfcs | NETMON_INTFCS
Log file name (fixed) | -l logfile | NETMON_LOGFILE
Prefix for log file (rolling) | -p prefix | NETMON_PREFIX
seconds between samples | -s seconds | NETMON_SECONDS

Regarding the network interface, if neither
"-i" nor "NETMON_INTFC" is supplied, the tool will look
for the file "/tmp/netmon.intfc". If it exists, its
contents will be used as the interface name.

Multiple network interfaces can be specified,
separated by spaces.
If supplied on the command line,
enclose in quotes.
Also, the special interface name '*'
can be specified to have netmon.sh
use "ifconfig" to find all non-loopback
running interfaces.

Regarding the log file, "-l" and "-p"
should be considered mutually exclusive.
If both are supplied, "-l" overrides "-p".
See next sections for more information on log files.


# Log File: Rolling

The default intent is to keep a week's worth of historical data.

The name of the netmon log file is normally a configurable
prefix followed by a dot ("."), followed by the 3-letter day of the
week. The prefix defaults to "/tmp/netmon.log".

Thus, if you don't override any defaults and you run
netmon.sh on a Monday, the output will be written to the file
"/tmp/netmon.log.Mon". If you leave it running past midnight,
the first time it goes to write a sample on Tuesday, it will write
to "/tmp/netmon.log.Tue". Six days later, on Sunday night,
as the time passes midnight and it becomes Monday again, the
"/tmp/netmon.log.Mon" file will be deleted and re-created with
the next sample.

Let's say you supply your own log prefix with "-p /tmp/mymon"
(or with "export NETMON_PREFIX=/tmp/mymon").
On Monday, it will write to "/tmp/mymon.Mon".


# Log File: Fixed

Alternatively, you can provide the full log file name using
"-l" or the environment variable "NETMON_LOGFILE", and no
day-of-week will be added to the file name.
Let say you supply "-l /tmp/mymon" (or with
export "NETMON_LOGFILE=/tmp/mymon").
All output will be written to "/tmp/mymon".

Note that setting the logfile with "-l" (or NETMON_LOGFILE)
will override prefix/day-of-week logging.
Also, use of "-l" will empty the contents of
the log file when netmon starts.


# Graceful Exit

The tool sets up a trap handler for control-C and kill.
It will wait up to one full second, do a final sample,
and exit normally.
The "netmon_stop.sh" uses kill to perform the
graceful exit.


# License

I want there to be NO barriers to using this code,
so I am releasing it to the public domain.
But "public domain" does not have an internationally agreed upon definition,
so I use CC0:

Copyright 2022-2022 Steven Ford http://geeky-boy.com and licensed
"public domain" style under
[CC0](http://creativecommons.org/publicdomain/zero/1.0/):
![CC0](https://licensebuttons.net/p/zero/1.0/88x31.png "CC0")

To the extent possible under law, the contributors to this project have
waived all copyright and related or neighboring rights to this work.
In other words, you can use this code for any purpose without any
restrictions. This work is published from: United States. The project home
is https://github.com/fordsfords/netmon

To contact me, Steve Ford, project owner, you can find my email address
at http://geeky-boy.com. Can't see it?  Keep looking.
