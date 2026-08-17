#!/bin/bash
#set -x 
#echo "in start single"
#pwd
#whoami
#ls -l /tmp
#cd /tmp
#pwd
#ls -l
#exit
./Plot_Voltage.sh $1 $2 $3 $4 $5&
#rm $5
disown
