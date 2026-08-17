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

. $INC_DIR/ftp_lib.sh
ftp_load_config "$INC_DIR"
. $INC_DIR/GNSS_Paths.cfg

if [ -z "${FTP_DOWNLOAD_JOBS[*]}" ]
then
   echo "FTP_DOWNLOAD_JOBS is not set and must be"
   logger "get_all_1_hour_ftp.sh: FTP_DOWNLOAD_JOBS is not set and must be"
   exit 200
fi

if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "get_all_1_hour_ftp.sh: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi


if [ -n "$1" ]; then
   rm -f /tmp/get_ftp.pid
fi

if [ -e /tmp/get_ftp.pid ]; then
   OLD_PID=`cat /tmp/get_ftp.pid`
   if kill -0 "$OLD_PID" 2>/dev/null; then
      echo "get_all_1_hour_ftp already running (pid $OLD_PID). delete /tmp/get_ftp.pid if it is not"
      logger "get_all_1_hour_ftp.sh: already running (pid $OLD_PID)"
      exit 101
   fi
   rm -f /tmp/get_ftp.pid
fi

echo $$ >/tmp/get_ftp.pid
PATH=/usr/local/bin:$PATH
logger "get_all_1_hour_ftp started"
logger "get_all_1_hour_ftp user" `whoami`

for job in "${FTP_DOWNLOAD_JOBS[@]}"
do
   IFS='|' read -r server remote_path older_than log_file <<< "$job"
   echo "Processing FTP download: $server:$remote_path"
   logger "get_all_1_hour_ftp: $server:$remote_path"
   ftp_mirror_download "$GNSS_RAW_BASE_DIR" "$server" "$remote_path" "$older_than" "$log_file" || {
      logger "get_all_1_hour_ftp: download failed for $server:$remote_path"
      echo "FTP download failed for $server:$remote_path"
   }
done

logger "get_all_1_hour_ftp " `pwd`

chmod 0755 -R $GNSS_RAW_BASE_DIR/*

#Robbie.sh
logger "get_all_1_hour_ftp downloaded"
logger "get_all_1_hour_ftp starting rename"
#ssh automat@automat.eng.trimble.com "/mnt/hgfs/admin/do_ren_automat.sh"
$INC_DIR/do_ren_all.sh
$INC_DIR/Make_All_24.sh
$INC_DIR/Make_All_24_Decimated.sh

$INC_DIR/Make_All_24_RINEX.sh &
$INC_DIR/Make_All_24_Plot.sh &
disown
rm -f /tmp/get_ftp.pid

logger "$0 finished"
exit 0
