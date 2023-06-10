#!/bin/bash
# V1.0 26 April 2020 - First cut

# Settings.. not many.
BadAge=86400  # 1 day, if a snapshot is older than a day it's bad.


# Some checking things are there, just in case.
function cmdcheck {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 not be found"
        exit
    fi
}
cmdcheck zfs
cmdcheck date
cmdcheck bc
cmdcheck tail
cmdcheck mktemp

# the function that does the grunt work, ish.
function checkage {
    SnapAge=-1        # by default SnapAge=-1 lets us know nothing was found.
    filesystem=$1     # makes the code below look nicer
    Now=$(date +%s)   # timestamp for right now, to compare to.

    # get unix timestamp of the age of the last snapshot
    LastSnap=$(zfs list -Hp -o creation -t snapshot $filesystem | tail -n 1 )
    if [[ ! -z "$LastSnap" ]]
    then
        SnapAge=$(echo $Now-$LastSnap | bc )
    fi
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
	printf '%ds\n' $S
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
    else
        echo -n "OK   $f: "
        displaytime $SnapAge
    fi
done

# clean up temp file
rm $tempfile

