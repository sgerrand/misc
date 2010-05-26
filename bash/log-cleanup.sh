#!/bin/bash
#
# log-cleanup.sh
#
# Copyright 2010 Sasha Gerrand <sasha@gerrand.net>
# 
# Cleans up log files in a designated directory by finding those that are older
# than a specified time period and deleting them.
#
VERSION="0.1"
# - 2010-05-26 Initial creation
#
USAGE="Usage: $0 -d LOG_DIRECTORY [-a OLDER_THAN_NUMBER_OF_DAYS] "
DAYS_DEFAULT=7
TS_FILE="/tmp/tmp_timestamp"

err () {
    echo "Error: $1"
    echo "$USAGE"
    exit 1
}

cleanup () {
    echo "Deleting $1"
    rm $1
    
    if [ "$?" -ne "0" ]
    then
        err "Unknown error occurred while deleting file ($1)"
    fi
}

archive () {
    if [ ! -f "$1" ]
    then
        err "Not a file ($1)"
    fi

    echo "Archiving $1"
    nice -n 10 gzip $file
}

# Catch no arguments being passed in
if [ "$#" -eq "0" ]
then
    err "No arguments were passed in"
fi

while getopts "d:a:" opt
do
    case $opt in
        d)
            LOG_DIR="$OPTARG"

            if [ ! -d "$LOG_DIR" ]
            then
                err "Not a directory ($LOG_DIR)"
            elif [ ! -r "$LOG_DIR" ]
            then 
                err "Directory is not readable ($LOG_DIR)"
            fi

        ;;
        a)
            DAYS="$OPTARG"
        ;;
        \?)
            err "Invalid option (-$OPTARG)"
        ;;
        *)
            err "Unknown variable (-$OPTARG)"
        ;;
    esac
done 

if [ -z "$DAYS" ]
then
    DAYS=$DAYS_DEFAULT
fi

# If the file older than the specified number of days, then delete it
#
files=$(find $LOG_DIR -type f -mtime +${DAYS})

for file in $files 
do
    # Ensure the file is not still open
    if [ -z "$(lsof $file)" ]
    then
        cleanup $file
    fi
done

# Archive files newer than the specified number of days
#
# Hack to pass a file with the appropriate timestamp to find
touch $TS_FILE --date="$(date --date="today - $DAYS days")"

files=$(find $LOG_DIR -type f -newer $TS_FILE)

for file in $files 
do
    # Ensure the file is not still open
    if [ -z "$(lsof $file)" ]
    then
        archive $file
    fi
done

# Finished
exit 0
