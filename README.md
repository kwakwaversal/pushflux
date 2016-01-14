# pushflux

pushflux - pushes data to influxdb

# Description

`pushflux` is a script that pushes (writes) data to influx. It's intended to give
bash scripts, Perl scripts, or anything that can write to the file system, a
simple way of writing data to influxdb.

You write your influx line to a monitored location, and sit back and relax as
`pushflux` writes the data.

If there is a problem Writing
to the influx database (as in it doesn't get a 200 response) it will retry at
the next pass.

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
