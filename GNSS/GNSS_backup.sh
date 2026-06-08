#!/bin/bash

logger "$0 started"
logger "$0 user" `whoami`
logger "$0 path $PATH"

INC_DIR=`dirname $0`

if [ $INC_DIR = "." ]
then
   INC_DIR=`pwd`
   echo "INC_DIR Set to current directory $INC_DIR"
fi

if [ -z "$INC_DIR" ]
then
   echo "INC_DIR is not set and must be"
   logger "$0: INC_DIR is not set and must be"
   exit 200
fi

. $INC_DIR/GNSS_Paths.cfg

if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "$0: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi

if [ -z "$BACKUP_SETS" ]
then
   echo "BACKUP_SETS is not set and must be"
   logger "$0: BACKUP_SETS is not set and must be"
   exit 200
fi

if [ -z "$BACKUP2_SETS" ]
then
   echo "BACKUP2_SETS is not set and must be"
   logger "$0: BACKUP2_SETS is not set and must be"
   exit 200
fi

if [ -z "$GNSS_BACKUP_MOUNT" ] || [ -z "$GNSS_BACKUP2_MOUNT" ]
then
   echo "GNSS_BACKUP_MOUNT and GNSS_BACKUP2_MOUNT must be set in GNSS_Paths.cfg"
   logger "$0: GNSS_BACKUP_MOUNT or GNSS_BACKUP2_MOUNT is not set"
   exit 200
fi

check_mount() {
   local mount_point="$1"
   if findmnt "$mount_point" > /dev/null 2>&1; then
      echo "$mount_point is mounted."
      return 0
   fi
   echo "$mount_point is NOT mounted."
   logger "$0: $mount_point is NOT mounted"
   return 1
}

check_mount "$GNSS_BACKUP_MOUNT" || exit 1
check_mount "$GNSS_BACKUP2_MOUNT" || exit 1

rsync_set() {
   local SET="$1"
   local DEST_MOUNT="$2"
   local src="$GNSS_RAW_BASE_DIR/$SET/"
   local dest="$DEST_MOUNT/GNSS_Data/$SET/"

   if [ ! -d "$GNSS_RAW_BASE_DIR/$SET" ]
   then
      echo "Skipping $SET: $GNSS_RAW_BASE_DIR/$SET not found"
      logger "$0: skipping $SET, source directory not found"
      return 0
   fi

   echo "Processing Set: $SET -> $dest"
   logger "$0: rsync $src -> $dest"
   rsync -av "$src" "$dest"
}

for SET in "${BACKUP_SETS[@]}"
do
   rsync_set "$SET" "$GNSS_BACKUP_MOUNT"
done

for SET in "${BACKUP2_SETS[@]}"
do
   rsync_set "$SET" "$GNSS_BACKUP2_MOUNT"
done

logger "$0 finished"
echo "$0 finished"
