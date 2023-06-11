#!/bin/bash
# V1.0 26 April 2020 - First cut
# V1.1 10/6/23 - Added human readable time
#              - Added locking, 2x of these on a server with lots of snapshots can kill things
# V1.2 11/6/23 - Added # of snapshots to output, which is helpful if you're looking for issues.

# Settings.. not many.
BadAge=86400  # 1 day, if a snapshot is older than a day it's bad.

# Some checking things are there, just in case.
function cmdcheck {
    if ! command -v $1 &> /dev/null
    then
        echo "Command $1 not found, needs to be installed?"
        exit 1
    fi
}
cmdcheck zfs
cmdcheck date
cmdcheck bc
cmdcheck tail
cmdcheck mktemp
cmdcheck flock
cmdcheck wc

# Locking file stuff.
LOCKFILE="/run/lock/snapage.lock"
touch $LOCKFILE  # Create lock
exec {FD}<>$LOCKFILE  # Get file descriptor
if ! flock -x -w 5 $FD; then
	echo "!  Is there another copy of snapage running?  Locked by $LOCKFILE"
	exit 1
fi

# the function that does the grunt work, ish.
function checkage {
	snaptempfile=$(mktemp /tmp/snapage.snaps.XXXXXXX)

    SnapAge=-1        # by default SnapAge=-1 lets us know nothing was found.
    filesystem=$1     # makes the code below look nicer
    Now=$(date +%s)   # timestamp for right now, to compare to.

    # get list of snapshots into a file first
    zfs list -Hp -o creation -t snapshot $filesystem > $snaptempfile 
    LastSnap=$( tail -n 1 $snaptempfile )
    SnapCount=$( wc -l < $snaptempfile )
    if [[ ! -z "$LastSnap" ]]
    then
        SnapAge=$(echo $Now-$LastSnap | bc )
    fi

    rm $snaptempfile
}

# Human readable time from seconds..
# https://unix.stackexchange.com/questions/27013/displaying-seconds-as-days-hours-mins-seconds
function displaytime {
	local T=$1
 	local D=$((T/60/60/24))
 	local H=$((T/60/60%24))
 	local M=$((T/60%60))
 	local S=$((T%60))
 	(( $D > 0 )) && printf '%dd ' $D
	(( $H > 0 )) && printf '%dh ' $H
	(( $M > 0 )) && printf '%dm ' $M
	printf '%ds' $S
}

# Get list of filesystems into temp file
tempfile=$(mktemp /tmp/snapage.XXXXXXXXX)
zfs list -H -o name > $tempfile

# itterate through the listing.
for f in $(cat $tempfile); do
    checkage $f

    if [[ $SnapAge -eq -1 ]] ; then
        echo    "NONE $f: "
    elif [[ "$SnapAge" -gt $BadAge ]]; then
        echo -n "OLD  $f: "
        displaytime $SnapAge
	echo "   (${SnapCount} snapshots)"
    else
        echo -n "OK   $f: "
        displaytime $SnapAge
	echo "   ( ${SnapCount} snapshots)"
    fi
done

# clean up temp file
rm $tempfile

