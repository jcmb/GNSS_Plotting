#! /bin/bash
#cd /Volumes/GPS_MYSQL/GPS_Data/BTN/24_HOUR
logger "$0 started"
logger "$0 user" `whoami`
logger "$0 path $PATH"

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

if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "get_all_1_hour_ftp.sh: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi


if [ -e /tmp/Plot_24_Voltage.pid ]
   then
   logger "$0 already running"
   echo $0 is still running. delete /tmp/Plot_24_Voltage.pid if it is not
   exit 101
   fi

echo $$ >/tmp/Plot_24_Voltage.pid

VOLTAGE_CGI_DIR=/mnt/GPS_Admin/cgi-bin/VoltagePlot
if [ ! -x "$VOLTAGE_CGI_DIR/Plot_Voltage_Dir_Script.sh" ]
then
   VOLTAGE_CGI_DIR=`cd "$INC_DIR/../cgi-bin/VoltagePlot" && pwd`
fi

Local_TZ=`TZ.py`
for SET in "${PLOT_SETS[@]}"
do
   echo "Processing Set: $SET"
   cd $GNSS_24_BASE_DIR/$SET/30s

   shopt -s nullglob
   for d in *
   do

       cd $GNSS_24_BASE_DIR/$SET/30s/$d
       logger "Voltage Plotting for $d"
       "$VOLTAGE_CGI_DIR/Plot_Voltage_Dir_Script.sh" .T02 $SET $d $Local_TZ *.T02
       "$VOLTAGE_CGI_DIR/Plot_Voltage_Dir_Script.sh" .T04 $SET $d $Local_TZ *.T04


   done
done

rm /tmp/Plot_24_Voltage.pid
logger "$0 finished"
