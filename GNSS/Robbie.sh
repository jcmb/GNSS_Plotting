#!/bin/bash

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

. $INC_DIR/GNSS_Paths.cfg

if [ -z "$GNSS_RAW_BASE_DIR" ]
then
   echo "GNSS_RAW_BASE_DIR is not set and must be"
   logger "$0: GNSS_RAW_BASE_DIR is not set and must be"
   exit 200
fi

if [ -z "$ROBBIE_SETS" ]
then
   echo "ROBBIE_SETS is not set and must be"
   logger "$0: ROBBIE_SETS is not set and must be"
   exit 200
fi

if [ -z "$ROBBIE_HTML" ]
then
   echo "ROBBIE_HTML is not set and must be"
   logger "$0: ROBBIE_HTML is not set and must be"
   exit 200
fi

if [ -z "$ROBBIE_STALE_HOURS" ]
then
   echo "ROBBIE_STALE_HOURS is not set and must be"
   logger "$0: ROBBIE_STALE_HOURS is not set and must be"
   exit 200
fi

TMP_HTML=/tmp/Robbie.html

logger "$0 started"
echo "$0 started"

{
   echo "<html>"
   echo '<head><title>GNSS Status</title><meta http-equiv="refresh" content="300"></head>'
   echo "<body>"
   echo "<h1>GNSS receiver status</h1>"
   date -u
   echo "<br/>"

   for SET in "${ROBBIE_SETS[@]}"
   do
      echo "<h2>$SET</h2><br/>"
      if [ ! -d "$GNSS_RAW_BASE_DIR/$SET" ]
      then
         echo "<p>Directory not found: $GNSS_RAW_BASE_DIR/$SET</p>"
         logger "$0: directory not found for $SET"
         continue
      fi
      "$INC_DIR/Robbie.py" "$GNSS_RAW_BASE_DIR/$SET" "$ROBBIE_STALE_HOURS"
   done

   echo "</body>"
   echo "</html>"
} > "$TMP_HTML"

mkdir -p "`dirname "$ROBBIE_HTML"`"
mv "$TMP_HTML" "$ROBBIE_HTML"

logger "$0 finished"
echo "$0 finished"
