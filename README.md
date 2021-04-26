# SnapAge

Script to report on age of snapshots...  For ZFS backup targets, manual checks / monitoring.

This is a somewhat blunt tool for a  fairly specific job.  It just lists all ZFS filesystems on a host, gets the timestamps of the latest snapshots for all of those filesystems and compares them to a fixed value.

I was looking for a simple way to get a list of filesystems with old snapshots on a large ZFS backup targe with 100's of filesystems and all of the options I found were part of much more complex tools and backup targets should be kept simple, so here it is.

The script has comments in it to help out understanding what I did.  It's real simple, just like me. :-)

I've tested this on Ubuntu 16.04, 18.04, 20.04 and SmartOS.  Anything with bash and ZFS should be fine.

## Install

Copy script it to /usr/bin, or somewhere else you can execute it from. Your choice really.

Call it what you want even, I've just used snapage where I'm using it.

## Usage

Run it..

The output will look like:

```
chrish@host:~$ snapage
NONE data: 
NONE data/backup: 
OK   data/backup/daily: 12566
OK   data/backup/daily/mcnas-ssd: 12563
OLD  data/backup/daily/mcnas-ssd/vms: 100345
```

etc.
 * 'NONE' is normal for container filesystems in most instances.
 * 'OK' means the latest snapshot on the filesystem is 
 * 'OLD' means that the snapshot is older than BadAge setting in the script.

