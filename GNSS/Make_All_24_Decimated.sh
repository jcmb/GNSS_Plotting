#! /bin/bash 
INC_DIR=`dirname $0`

if [ $INC_DIR = "." ]
then
   INC_DIR=`pwd`
fi

if [ -z "$INC_DIR" ]
then
   echo "INC_DIR is not set and must be"
   logger "$0: INC_DIR is not set and must be"
   exit 200
fi


. $INC_DIR/ftp_user.cfg
. $INC_DIR/GNSS_Paths.cfg

if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "$0: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi

logger "Make_All_24_Decimated.sh Started $@"
echo "Make_All_24_Decimated.sh Started $@"

if [ -e /tmp/Decimate_24.pid ]
   then
   logger "Make_All_24_Decimate.sh already running"
   echo Make_All_24_Decimate.sh is still running. delete /tmp/Decimate_24.pid if it is \
not
   exit 101
   fi

echo $$ >/tmp/Decimate_24.pid

shopt -s nullglob

for SET in "${DECIMATE_SETS[@]}"
do
   echo "Processing Set: $SET"
   cd $GNSS_24_BASE_DIR/$SET/ORG

   for D in *
   do
      if [ -d "$GNSS_RAW_BASE_DIR/$SET/$D" ]
      then
         echo "Processing Receiver: $SET:$D"
         mkdir -p $GNSS_24_BASE_DIR/$SET/1Hz/$D
         mkdir -p $GNSS_24_BASE_DIR/$SET/30s/$D
         cd $GNSS_24_BASE_DIR/$SET/ORG/$D

	 $INC_DIR/Decimate_All_24_Directory.sh T02 $SET 1Hz $D 1 
	 $INC_DIR/Decimate_All_24_Directory.sh T04 $SET 1Hz $D 1
	 $INC_DIR/Decimate_All_24_Directory.sh T02 $SET 30s $D 30
	 $INC_DIR/Decimate_All_24_Directory.sh T04 $SET 30s $D 30
      fi
   done
done

rm /tmp/Decimate_24.pid


logger "Make_All_24_Decimated.sh Finished"
echo "Make_All_24_Decimated.sh Finished"
