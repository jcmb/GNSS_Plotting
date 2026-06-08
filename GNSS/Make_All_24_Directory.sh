#! /bin/bash 
logger "Make_All_24_Directrory .sh Started $@"
shopt -s nullglob

PATH=/usr/local/bin:$PATH

INC_DIR=`dirname $0`
if [ -z "$INC_DIR" ]
then
   echo "INC_DIR is not set and must be"
   logger "do_ren_mac.sh: INC_DIR is not set and must be"
   exit 200
fi

. $INC_DIR/ftp_user.cfg
. $INC_DIR/GNSS_Paths.cfg

if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "do_ren_mac.sh: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi

shopt -s nullglob
# We do $4 here so that we ignore files that have not been renamed yet.

for f in $4_*23.$1
do
#   echo $f
   LEN=${#f}
#   echo $LEN
   LEN=`expr $LEN - 6`
#   echo $LEN

   BASE=${f:0:$LEN}
#   echo $2
#   echo $BASE
   PREFIX_LEN=${#4}
   PREFIX_LEN=`expr $PREFIX_LEN + 1` #Have an _ in the name
#   echo "Prefix $PREFIX_LEN"
   DATE=${BASE:$PREFIX_LEN}
   if [ ! -e $GNSS_24_BASE_DIR/$2/$3/$4/$BASE.$1 ]
   then
       $INC_DIR/Make_24_Hour.sh $BASE $1
       mkdir -p $GNSS_24_BASE_DIR/$2/$3/$4/
       cp $BASE.$1 $GNSS_24_BASE_DIR/$2/$3/$4/$BASE.$1
       rm $BASE.$1

       mkdir -p $GNSS_24_BASE_DIR/Date/$2/$3/$DATE

       ln -s $GNSS_24_BASE_DIR/$2/$3/$4/$BASE.$1 $GNSS_24_BASE_DIR/Date/$2/$3/$DATE/$BASE.$1
   fi
done
logger "Make_All_24_Directrory .sh ended"
