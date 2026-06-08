#! /bin/bash

logger "$0 Started"

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
   logger "$0: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi


shopt -s nullglob
EXT=T02

for SET in "${DECIMATE_SETS[@]}"
do
   echo "Processing $SET:$RATE"
   echo RATES_SETS
   for RATE in "${RATES_SETS[@]}"
      do
      cd  $GNSS_24_BASE_DIR/$SET/$RATE

      echo "Processing $SET:$RATE"
      for d in *
      do
         echo "Base: $d"
         cd $GNSS_24_BASE_DIR/$SET/$RATE/$d

         for f in $d_*.$EXT
         do
            LEN=${#f}
            LEN=`expr $LEN - 4`

            BASE=${f:0:$LEN}
            PREFIX_LEN=${#d}
            PREFIX_LEN=`expr $PREFIX_LEN + 1` #Have an _ in the name
            DATE=${BASE:$PREFIX_LEN}
            mkdir -p $GNSS_24_BASE_DIR/$SET/Date/$RATE/$DATE
            if [ ! -e $GNSS_24_BASE_DIR/$SET/Date/$RATE/$DATE/$f ]
            then
               echo "$f $d $DATE"
               ln $GNSS_24_BASE_DIR/$SET/$RATE/$d/$f $GNSS_24_BASE_DIR/$SET/Date/$RATE/$DATE/$f
            fi

         done
      done
   done
done
logger "$0 Finished"

