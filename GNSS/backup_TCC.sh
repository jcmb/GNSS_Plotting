#!/bin/bash
unset ftp_proxy

if [ -e /tmp/backup_TCC.pid ]
   then
   echo $0 is still running. delete /tmp/backup_TCC.pid if it is not
   exit 101
   fi

echo $$ > /tmp/backup_TCC.pid

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

. $INC_DIR/ftp_lib.sh
ftp_load_config "$INC_DIR"
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

if [ -z "$FTP_TCC_UPLOAD_SERVER" ] || [ -z "$FTP_BACKUP_PATH" ]
then
   echo "FTP_TCC_UPLOAD_SERVER and FTP_BACKUP_PATH must be set in ftp_servers.cfg"
   logger "$0: FTP_TCC_UPLOAD_SERVER or FTP_BACKUP_PATH is not set"
   exit 200
fi

PATH=/usr/local/bin:$PATH
logger "$0 started"
logger "$0 user" `whoami`
echo "$0 started"

for SET in "${BACKUP_SETS[@]}"
do
   if [ ! -d "$GNSS_RAW_BASE_DIR/$SET" ]
   then
      echo "Skipping $SET: $GNSS_RAW_BASE_DIR/$SET not found"
      logger "$0: skipping $SET, directory not found"
      continue
   fi

   echo "Backing up set: $SET"
   logger "$0: backing up $SET from $GNSS_RAW_BASE_DIR/$SET"
   ftp_mirror_upload "$GNSS_RAW_BASE_DIR/$SET" "$FTP_TCC_UPLOAD_SERVER" "$FTP_BACKUP_PATH/$SET" "/tmp/backup_TCC_${SET}.log" || {
      logger "$0: upload failed for $SET"
      echo "FTP upload failed for $SET"
   }

done

rm /tmp/backup_TCC.pid
logger "$0 finished"
echo "$0 finished"
