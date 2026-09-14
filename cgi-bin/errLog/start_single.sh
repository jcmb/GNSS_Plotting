#!/bin/bash
logger "errLog for $1 "
#echo "start single $2****"
#echo $1 
cd /tmp
/usr/lib/cgi-bin/errLog/errLog $1
#rm $1
