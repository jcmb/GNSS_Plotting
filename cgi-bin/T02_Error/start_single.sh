#!/bin/bash
logger "T02_Error for $1 $2"
logger `whereis viewdat`
#echo "start single $2****"
#echo $1 
cd /tmp
viewdat -d35:7 $1 |  tail -n +5
rm $1
