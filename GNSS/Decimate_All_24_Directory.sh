#! /bin/bash

INC_DIR=`dirname $0`

if [ $INC_DIR = "." ]
then
   INC_DIR=`pwd`
   echo "INC_DIR Set to current directory $INC_DIR"
fi


if [ -z "$INC_DIR" ]
then
   echo "INC_DIR is not set and must be"
   logger "$0: INC_DIR is not set and must be"
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

logger  "$0 started $@"

for f in $4_*.$1
do

   if [ ! -e $GNSS_24_BASE_DIR/$2/$3/$4/$f ]
   then
       /usr/local/bin/t0x2t0x  -obs_dec=$5 -pos_dec=$5 $f $GNSS_24_BASE_DIR/$2/$3/$4/$f >/dev/null
#       if [ $1 == T04 ]
#       then
#	   BASE=`basename $f .$1`
#	   if [ ! -e  $GNSS_24_BASE_DIR/$2/$3/$4/$BASE.T02 ]
#	       then
#               echo "Converting $f to $BASE.T02"
#               /usr/local/bin/t0x2t0x $f $BASE.T02 >/dev/null
#               echo "Decimating $f to rate of $5. Into $GNSS_24_BASE_DIR/$2/$3/$4/$BASE.T02"
#               /usr/local/bin/t0x2t0x  -obs_dec=$5 -pos_dec=$5 $BASE.T02 $GNSS_24_BASE_DIR/$2/$3/$4/$BASE.T02 >/dev/null
#               rm $BASE.T02
#	       fi
#       else
#	   echo "Decimating $f to rate of $5. Into $GNSS_24_BASE_DIR/$2/$3/$4/"
#	   /usr/local/bin/t0x2t0x  -obs_dec=$5 -pos_dec=$5 $f $GNSS_24_BASE_DIR/$2/$3/$4/$f >/dev/null
#       fi
   fi

done
