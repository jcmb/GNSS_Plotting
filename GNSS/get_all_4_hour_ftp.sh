#!/bin/bash
if [ -e /tmp/get_4_ftp.pid ]
   then
   echo Get_Ftp is still running. delete /tmp/get_4_ftp.pid if it is not
   logger "get_all_4_hour_ftp already running"
   exit 101
   fi

logger "get_all_4_hour_ftp started"

echo $$ >/tmp/get_4_ftp.pid
PATH=/opt/local/bin:$PATH

cd /Volumes/GPS_MYSQL/BASES/4_HOUR/405

lftp <<EOF
set xfer:clobber on
open -u tac,mes4age ftp.trimble.com
cd /pub/to_tac/gkirk/405
mget -d -E *
EOF

#Robbie.sh
logger "get_all_4_hour_ftp downloaded"
logger "get_all_4_hour_ftp starting rename"
#ssh automat@automat.eng.trimble.com "/admin/do_ren.sh"
/Volumes/GPS_MYSQL/admin/do_ren.sh

logger "get_all_4_hour_ftp finished"
rm /tmp/get_4_ftp.pid


exit 0

