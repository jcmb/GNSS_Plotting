#!/bin/bash
PATH=$PATH:/opt/local/bin
unset ftp_proxy

if [ -e /tmp/backup_Terrasat.pid ]
   then
   echo $0 is still running. delete /tmp/backup_Terrasat.pid if it is not
   exit 101
   fi

echo $$ > /tmp/backup_Terrasat.pid

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

#. $INC_DIR/ftp_user.cfg
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
cd $GNSS_RAW_BASE_DIR/Terrasat/
logger "$0 " `pwd`



lftp  <<EOF
set xfer:clobber on
set xfer:log
open -u  TCD,humid-DENIAL det-qastore.eu.trimblecorp.net:21 
mirror --reverse --ignore-time --parallel --log=/tmp/backup_Terrasat.log
EOF


rm /tmp/backup_Terrasat.pid
logger "$0 finished"
echo "$0 finished"
