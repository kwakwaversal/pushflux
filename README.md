# pushflux

pushflux - writes data to an [InfluxDB](https://influxdata.com/) from your logs

# Description

`pushflux` is a script that pushes (writes) data to InfluxDB from log files.
It's intended to give bash scripts, Perl scripts, or anything that can write to
the file system, a simple way of writing data to InfluxDB.

You write your influx line (must be using the [Line
Protocol](https://docs.influxdata.com/influxdb/v0.9/write_protocols/line/)) to a
file in the monitored folder location, and sit back and relax as `pushflux`
writes the data. `pushflux` monitors the folder `/var/lib/pushflux` by default
for any files that have changed in the last `x` mins (2 mins by default).

The folder layout and file extension (`*.log` by default) is important, as
that's how `pushflux` knows where to write the data, and which files to monitor
respectively.

```
# expected path format
/var/lib/pushflux/$host/$database/$filename.$ext

# writes to http://127.0.0.1:8086/write?db=mydatabase
/var/lib/pushflux/127.0.0.1/mydatabase/influx.log

# bash example
$ echo "mymeasurement,domain=pushflux.org value=1 $(date +%s%N)" >> /var/lib/pushflux/127.0.0.1/mydatabase/influx.log
```

If there is a problem writing to the InfluxDB (as in it doesn't get a 200
response) it will retry at the next pass.

# Configuration options

The following options can be set.

```
my $buffer      = '100';                # flush buffer to influx after $buffer lines
my $mmin        = '-2';                 # find files modified in last 2 mins
my $monitor     = '/var/lib/pushflux';  # folder to monitor
my $monitor_ext = 'log';                # file extension to include in pushes
my $symlinks    = '-L';                 # find will follow symlinks
```

# Installing

`pushflux` has been tested on Debian only, but should work on any OS with Perl
5.10.1 and higher.

## Setup

```
  $ sudo mkdir -p /var/run/pushflux
  $ sudo chmod 777 /var/run/pushflux
  $ sudo mkdir -p /var/lib/pushflux
  $ sudo chmod 777 /var/lib/pushflux
```

## Crontab

`pushflux` is intended to by run as a cronjob every minute.

```
# m h  dom mon dow
  * *  *   *   *  /opt/pushflux/bin/pushflux
```
