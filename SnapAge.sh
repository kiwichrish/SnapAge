#!/bin/bash

# V1.0 26 April 2020 - First cut

# Settings.. not many.
BadAge=86400  # 1 day, if a snapshot is older than a day it's bad.

function checkage {
    # by default SnapAge=-1 lets us know nothing was found.
    SnapAge=-1
    filesystem=$1
    Now=$(date +%s)

    LastSnap=$(zfs list -Hp -o creation -t snapshot $filesystem | tail -n 1 )
    if [[ ! -z "$LastSnap" ]]
    then
        SnapAge=$(echo $Now-$LastSnap | bc )
    fi
}

# Get list of filesystems
zfs list -H -o name > /tmp/filesystems.tmp

# itterate through it
for f in $(cat /tmp/filesystems.tmp); do
    checkage $f

    if [[ $SnapAge -eq -1 ]] ; then
        echo "NONE $f: "
    elif [[ "$SnapAge" -gt $BadAge ]]; then
        echo -n "OLD $f: "
        echo $SnapAge
    else
        echo -n "OK  $f: "
        echo $SnapAge
    fi
done