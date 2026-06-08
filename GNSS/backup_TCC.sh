#!/bin/bash
PATH=$PATH:/opt/local/bin
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
   logger "do_ren_mac.sh: INC_DIR is not set and must be"
   exit 200
fi

. $INC_DIR/ftp_user.cfg
. $INC_DIR/GNSS_Paths.cfg

if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "$0: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi


PATH=/opt/local/bin:$PATH
logger "$0 started: $0"
logger "backup_btn user" `whoami`
echo "$0 started: $0"

#$INC_DIR/do_ren_all.sh

cd $GNSS_RAW_BASE_DIR/

logger "$0 " `pwd`

#rsync -v --itemize-changes --dry-run --ignore-times  --progress -r . rsync://hcc.trimble.com/BTN
#rsync -a  . rsync://hcc.trimble.com/GNSS



cd $GNSS_RAW_BASE_DIR/BASES

lftp  <<EOF
set xfer:clobber on
set xfer:log
open -u $FTP_USER $FTP_SERVER
cd $FTP_BACKUP_PATH/BASES
mirror --reverse --ignore-time --parallel --log=/tmp/backup_TCC.log
EOF


rm /tmp/backup_TCC.pid
logger "$0 finished"
echo "$0 finished"
