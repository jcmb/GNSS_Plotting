#!/bin/bash
PATH=/usr/local/bin:$PATH

INC_DIR=`dirname $0`
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
logger  "do_ren.sh started"



for SET in "${RENAME_SETS[@]}"
do
   echo "Processing Set: $SET"
   cd $GNSS_RAW_BASE_DIR/$SET/

   for D in *
   do
      if [ -d "$GNSS_RAW_BASE_DIR/$SET/$D" ]
      then
         echo "Processing Receiver: $SET:$D"
         cd $GNSS_RAW_BASE_DIR/$SET/$D
#         echo find . -not -name $D"_*.T02" -type f
         find . -not -name $D"_*.T02" -type f| grep T02 | xargs -L 1 rdatname.sh $D DELETE
      fi
   done
done

logger  "do_ren.sh finished"
