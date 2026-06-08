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
   logger "do_ren_mac.sh: INC_DIR is not set and must be"
   exit 200
fi

. $INC_DIR/GNSS_Paths.cfg

if [ -z "$BACKUP_SETS" ]
then
   echo "BACKUP_SETS is not set and must be"
   logger "GNSS_backup.sh: BACKUP_SET is not set and must be"
   exit 200
fi

if [ -z "$BACKUP2_SETS" ]
then
   echo "BACKUP2_SETS is not set and must be"
   logger "GNSS_backup.sh: BACKUP2_SET is not set and must be"
   exit 200
fi

MOUNT_POINT="/mnt/GPS_Admin_Backup"
if findmnt "$MOUNT_POINT" > /dev/null 2>&1; then
    echo "$MOUNT_POINT is mounted."
else
    echo "$MOUNT_POINT is NOT mounted."
    logger "GNSS_backup.sh: $MOUNT_POINT is NOT mounted."BACKUP2_SET is not set and must be"
    exit 1
    # Example: Try to mount it
    # mount /dev/sdX1 $MOUNT_POINT
fi

MOUNT_POINT="//mnt/GNSS_Non_Base_Backup"
if findmnt "$MOUNT_POINT" > /dev/null 2>&1; then
    echo "$MOUNT_POINT is mounted."
else
    echo "$MOUNT_POINT is NOT mounted."
    logger "GNSS_backup.sh: $MOUNT_POINT is NOT mounted."BACKUP2_SET is not set and must be"
    exit 1
    # Example: Try to mount it
    # mount /dev/sdX1 $MOUNT_POINT
fi

for SET in "${BACKUP_SETS[@]}"
do
   echo "Processing Set: $SET"
   sudo rsync -av $1 /mnt/GPS_Admin/GNSS_Data/$SET/ /mnt/GPS_Admin_Backup/GNSS_Data/$SET/
done

for SET in "${BACKUP2_SETS[@]}"
do
   echo "Processing Set: $SET"
   sudo rsync -av $1 /mnt/GPS_Admin/GNSS_Data/$SET/ /mnt/GNSS_Non_Base_Backup/GNSS_Data/$SET/
done



