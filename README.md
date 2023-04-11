# netmon

Monitoring script for hosts running UDP-intensive applications.

# Table of contents
- [netmon](#netmon)
- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [Usage:](#usage)
- [Configuration](#configuration)
- [Log File Rolling](#log-file-rolling)
- [Log File Fixed](#log-file-fixed)
- [Graceful Exit](#graceful-exit)
- [License](#license)

<sup>(table of contents from https://luciopaiva.com/markdown-toc/)</sup>

# Introduction

Over the years, I've had many occasions where a network-intensive application
had problems, and I've wanted information about the system on which it
is running. Things like "netstat", "ethtool -S', and if Onload is being used,
"onload_stackdump lots". Typically I just create an ad-hoc script that wakes
up every few minutes and runs the commands.

More recently, I've been working with somebody else, and have made various
improvements to the typical ad-hoc script. So I decided to put it up,
not so much because I think it is a ready-for-prime-time monitoring tool,
but more because it has a few little scripting features that I want to
remember for the future.

# Usage:

Here's the help:
````
Usage: netmon.sh [-h] [-i intfc] [-l logfile] [-p prefix] [-s seconds]
Where:
  -h help
  -i intfc - interface for ethtool; default: /tmp/netmon.intfc
  -l logfile - Log file path (no day of week appended).
  -p prefix - Prefix path, appended with day of week; default: /tmp/netmon.log
  -s seconds - Seconds to wait between samples; default: 600 (10 min)
See https://github.com/fordsfords/netmon for more information.
````

netmon.sh is intended to be run in the background.
As it starts up, it records the following information:
* uname -r
* cat /etc/os-release
* uptime
* sysctl net.core.rmem_max
* lscpu

Then, it loops periodically, recording a "sample" consisting of:
* netstat -g -n
* ethtool -S <interface>
* onload_stackdump lots
* ifconfig
* netstat -us

Note that if the tool detects that ethtool or onload_stackdump
doesn't work, it skips that non-working command. For example,
if a host doesn't have Onload, the "onload_stackdump" is
skipped.

The tool will run until killed (with control-C or with "kill <pid>").


# Configuration

The tool can be configured via command-line options
or with environment variables.
If both are supplied, the command-line options have priority.

Item | Command-line Option | Environment Variable
---- | ------------------- | --------------------
Network Interface | -i intfc | NETMON_INTFC
Log file name (fixed) | -l logfile | NETMON_LOGFILE
Prefix for log file (rolling) | -p prefix | NETMON_PREFIX
seconds between samples | -s seconds | NETMON_SECONDS

Regarding the network interface, if neither
"-i" nor "NETMON_INTFC" is supplied, the tool will look
for the file "/tmp/netmon.intfc". If it exists, it's
contents will be used as the interface name.

Regarding the log file, "-l" and "-p"
should be considered mutually-exclusive.
If both are supplied, "-l" overrides "-p".
See next sections for more information on log files.


# Log File Rolling

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
"/tmp/netmon.log.Mon" file will be deleted and re-craeted with
the next sample.

Let's say you supply your own log prefix with "-p /tmp/mymon"
(or with "export NETMON_PREFIX=/tmp/mymon").
On Monday, it will write to "/tmp/mymon.Mon".


# Log File Fixed

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
restrictions.  This work is published from: United States.  The project home
is https://github.com/fordsfords/netmon

To contact me, Steve Ford, project owner, you can find my email address
at http://geeky-boy.com.  Can't see it?  Keep looking.
