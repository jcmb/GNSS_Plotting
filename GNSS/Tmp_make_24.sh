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

. $INC_DIR/GNSS_Paths.cfg

logger "get_all_1_hour_ftp downloaded"
logger "get_all_1_hour_ftp starting rename"
#ssh automat@automat.eng.trimble.com "/mnt/hgfs/admin/do_ren_automat.sh"
$INC_DIR/Make_All_24.sh&
#$INC_DIR/Make_All_24_Decimated.sh
#$INC_DIR/Make_All_24_RINEX.sh &
#$INC_DIR/Make_All_24_Plot.sh &
disown
rm /tmp/get_ftp.pid

logger "$0 finished"
exit 0
