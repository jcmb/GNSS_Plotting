#! /bin/bash
#cd /Volumes/GPS_MYSQL/GPS_Data/BTN/24_HOUR
logger "DVB_Files.sh started $@"
logger "DVB_Files.sh user" `whoami`

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


shopt -s nullglob

for SET in "${DVB_SETS[@]}"
do
   cd $GNSS_24_BASE_DIR/$SET/ORG/
   for d in *
   do
#   cd /Volumes/GPS_MYSQL/GPS_Data/BTN/24_HOUR/$d
     echo "Processing base: $SET:$d"
     cd  $GNSS_24_BASE_DIR/$SET/ORG/$d
     for F in *.T0*
        do
        mkdir -p $GNSS_24_BASE_DIR/DVB/$SET/$d
   #   /Volumes/GPS_MYSQL/admin/Plot_File_Script.sh BTN $d *.T02
        if [ ! -f .$F.DVB ]
           then
           ln $GNSS_24_BASE_DIR/$SET/ORG/$d/$F $GNSS_24_BASE_DIR/DVB/$SET/$d/$F
           echo "$d $F Linked"
           touch .$F.DVB
           fi
        done
   done
done

logger "DVB_Files.sh stopped"
