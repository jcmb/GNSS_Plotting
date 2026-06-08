#! /bin/bash

E_NO_ARGS=65
USAGE="Usage: $0 Type PROJ Station TZ GNSSFile"

if [ $# -lt 5 ]
then
  echo $USAGE
  exit $E_NO_ARGS
fi

normalDir=`cd "$(dirname "$0")" && pwd`
PATH=$normalDir:/usr/local/bin:$PATH

GNSS_CFG_DIR=`cd "$normalDir/../../admin/GNSS" 2>/dev/null && pwd`
if [ -z "$GNSS_CFG_DIR" ] || [ ! -f "$GNSS_CFG_DIR/GNSS_Paths.cfg" ]
then
   GNSS_CFG_DIR=/mnt/GPS_Admin/admin/GNSS
fi

if [ ! -f "$GNSS_CFG_DIR/GNSS_Paths.cfg" ]
then
   echo "GNSS_Paths.cfg not found"
   logger "$0: GNSS_Paths.cfg not found"
   exit 200
fi

. "$GNSS_CFG_DIR/GNSS_Paths.cfg"

if [ -z "$GNSS_RESULTS_DIR" ]
then
   echo "GNSS_RESULTS_DIR is not set and must be"
   logger "$0: GNSS_RESULTS_DIR is not set and must be"
   exit 200
fi

TYPE=$1
shift

PROJ=$1
shift

STATION=$1
shift

Local_TZ=$1
shift

INPUT_FILE=$1

if [ ! -f "$INPUT_FILE" ]
then
   echo "Input file not found: $INPUT_FILE"
   logger "$0: input file not found: $INPUT_FILE"
   exit 1
fi

FileFull=`basename "$INPUT_FILE"`
File=`basename "$INPUT_FILE" "$TYPE"`
RESULT_DIR="$GNSS_RESULTS_DIR/Voltage/$PROJ/$STATION/$File"

mkdir -p "$RESULT_DIR"

echo "Plotting Voltage for $File"
logger "$0: plotting voltage for $File from $INPUT_FILE"

viewdat -d40 -x "$INPUT_FILE" | "$normalDir/X40_Power_To_Flat.py" > "$RESULT_DIR/file"

cd "$RESULT_DIR" || exit 1

if [ -s file ]
then
    echo "$File Has Voltage/Temp Records"
    logger "$0: $File has voltage/temp records"

    echo "$File" >file.html

    echo name="'$File: '" >file.plt
    echo Local_TZ="$Local_TZ" >>file.plt

    gnuplot file.plt "$normalDir/X40_Plot.plt"
    ln -sf "$normalDir/index.shtml" index.shtml
else
    echo "$File does not have Voltage/Temp Records"
    logger "$0: $File does not have voltage/temp records"
    rm -f file
    cd "$GNSS_RESULTS_DIR/Voltage/$PROJ/$STATION" || exit 1
    rmdir "$File" 2>/dev/null
fi
