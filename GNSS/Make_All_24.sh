#! /bin/bash

echo "Make_All_24.sh Started $@"
logger "Make_All_24.sh Started $@"
shopt -s nullglob

PATH=/usr/local/bin:$PATH

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
   logger "do_ren_mac.sh: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi

shopt -s nullglob
logger  "Make_All_24.sh started: $@"
echo  "Make_All_24.sh started: $@"



for SET in "${HOUR24_SETS[@]}"
do
   echo "Processing Set: $SET"
   cd $GNSS_RAW_BASE_DIR/$SET/

   for D in *
   do
      if [ -d "$GNSS_RAW_BASE_DIR/$SET/$D" ]
      then
         echo "Processing Receiver: $SET:$D"
         cd $GNSS_RAW_BASE_DIR/$SET/$D
         mkdir -p $GNSS_24_BASE_DIR/$SET/ORG/$D/
         $INC_DIR/Make_All_24_Directory.sh T02 $SET ORG $D
         $INC_DIR/Make_All_24_Directory.sh T04 $SET ORG $D
         $INC_DIR/Make_Odd_Even_24.sh T02 $GNSS_24_BASE_DIR/$SET/ORG/$D/
         $INC_DIR/Make_Odd_Even_24.sh T04 $GNSS_24_BASE_DIR/$SET/ORG/$D/
         $INC_DIR/Make_Odd_Even_24.sh T02 $GNSS_24_BASE_DIR/$SET/1Hz/$D/
         $INC_DIR/Make_Odd_Even_24.sh T04 $GNSS_24_BASE_DIR/$SET/1Hz/$D/
         $INC_DIR/Make_Odd_Even_24.sh T02 $GNSS_24_BASE_DIR/$SET/30s/$D/
         $INC_DIR/Make_Odd_Even_24.sh T04 $GNSS_24_BASE_DIR/$SET/30s/$D/
      fi
   done
done


#echo "Creating Plots"
#$INC_DIR/DVB_Files.sh
logger "Make_All_24.sh STOPPED"
echo "Make_All_24.sh STOPPED"
