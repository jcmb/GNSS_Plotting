#!/bin/bash
if [ -e /tmp/get_ftp.pid ]
   then
   echo Get_Ftp is still running. delete /tmp/get_ftp.pid if it is not
   exit 101
   fi

echo $$ >/tmp/get_ftp.pid

cd /data/GPS/

lftp <<EOF
open -u tac,mes4age ftp.trimble.com
cd /pub/to_tac/gkirk/
lcd I15
cd I15
mget -d -E */*
EOF

rm /tmp/get_ftp.pid
