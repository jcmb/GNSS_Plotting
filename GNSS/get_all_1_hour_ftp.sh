#!/bin/bash
unset ftp_proxy

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

if [ -z "$FTP_USER" ]
then
   echo "FTP_USER is not set and must be"
   logger "get_all_1_hour_ftp.sh: FTP_USER is not set and must be"
   exit 200
fi



if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "get_all_1_hour_ftp.sh: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi


if [ -n "$1" ]; then
  rm /tmp/get_ftp.pid
  fi


echo $$ >/tmp/get_ftp.pid
PATH=/opt/local/bin:$PATH
logger "get_all_1_hour_ftp started"
logger "get_all_1_hour_ftp user" `whoami`

. $INC_DIR/ftp_transfer.cfg

echo "Processing: Transfer.Trimble-wco.com"

#for SET in "${SETS[@]}"
#do
#    echo "Processing: " $GNSS_RAW_BASE_DIR/$SET/
#    if [ ! -d "$GNSS_RAW_BASE_DIR/$SET/" ]; then
#	mkdir -p "$GNSS_RAW_BASE_DIR/$SET/"
#    fi    
#   cd $GNSS_RAW_BASE_DIR/$SET/ 
#
#   logger "get_all_1_hour_ftp " `pwd`
#
#done


cd $GNSS_RAW_BASE_DIR
lftp <<EOF
set xfer:clobber on
set xfer:log true
#set xfer:log-file "/tmp/get_all_1.log"
open -u $FTP_USER $FTP_SERVER
cd TCC/BTN/GNSSTransfer/
# mget -d -E */*
mirror --older-than=now-15minutes --Remove-source-files --continue .
EOF

cd $GNSS_RAW_BASE_DIR
lftp <<EOF
set xfer:clobber on
set xfer:log true
#set xfer:log-file "/tmp/get_all_1.log"
open -u $FTP_USER $FTP_SERVER
cd MP/
#mget -d -E */*
mirror --older-than=now-15minutes --Remove-source-files --continue .
EOF

echo "Processing: TCC"

#for SET in "${SETS[@]}"
#do
#   echo "Processing: " $GNSS_RAW_BASE_DIR/$SET/ 
#   cd $GNSS_RAW_BASE_DIR/$SET/
#
#   logger "get_all_1_hour_ftp " `pwd`
#
#done


cd $GNSS_RAW_BASE_DIR
lftp <<EOF
set xfer:clobber on
set xfer:log true
set xfer:log-file "/tmp/get_all_1.log"
open -u $FTP_USER myconnectedsite.com
#cd /TCC/btn/GNSSTransfer/$SET
cd /TCC/btn/GNSSTransfer/
mirror --older-than=now-5minutes --Remove-source-files --continue .
#mget -d -E */*
EOF

logger "get_all_1_hour_ftp " `pwd`

chmod 0755 -R $GNSS_RAW_BASE_DIR/*

#Robbie.sh
logger "get_all_1_hour_ftp downloaded"
logger "get_all_1_hour_ftp starting rename"
#ssh automat@automat.eng.trimble.com "/mnt/hgfs/admin/do_ren_automat.sh"
$INC_DIR/do_ren_all.sh
$INC_DIR/Make_All_24.sh
$INC_DIR/Make_All_24_Decimated.sh

if [ -e /tmp/get_ftp.pid ]
   then
   echo Get_Ftp Plotting is still running. delete /tmp/get_ftp.pid if it is not
   exit 101
   fi


$INC_DIR/Make_All_24_RINEX.sh &
$INC_DIR/Make_All_24_Plot.sh &
disown
rm /tmp/get_ftp.pid

logger "$0 finished"
exit 0
