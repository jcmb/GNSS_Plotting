#! /bin/bash
#SERVER=gnssplot.eng.trimble.com
#SERVER=192.168.250.139

E_NO_ARGS=65

USAGE="Usage: $0 Type PROJ Station GNSSFile1 GNSSFile2 .. GNSSFileN"


if [ $# -eq 0 ]  # Must have command-line args to demo script.
then
  echo $USAGE
  exit $E_NO_ARGS
fi

TYPE=$1
shift

PROJ=$1
shift

STATION=$1
shift

DIR=`pwd`
INC_DIR=`cd "$(dirname "$0")" && pwd`
POSITION_CGI_DIR=/mnt/GPS_Admin/cgi-bin/PositionPlot
if [ ! -x "$POSITION_CGI_DIR/plot_single_cgi.sh" ]
then
   POSITION_CGI_DIR=`cd "$INC_DIR/../cgi-bin/PositionPlot" && pwd`
fi

mkdir /run/shm/Position 2>/dev/null

while (( "$#" )); do
    if [ ! -f .$1.plot ]
    then
	echo "Plotting " $1
        echo "ln -s $DIR/$1  /run/shm/Position"
        ln -s $DIR/$1  /run/shm/Position
	echo "$POSITION_CGI_DIR/plot_single_cgi.sh /run/shm/$1 $TYPE -1 $STATION -1 0 0/$PROJ -1"
        "$POSITION_CGI_DIR/plot_single_cgi.sh" /run/shm/Position/$1 $TYPE -1 $STATION -1 0 0 /$PROJ -1
#        curl  -F project=$TYPE -F Point=$STATION -F file=@$1 http://$SERVER/cgi-bin/PositionPlot/T02_2_PNG.pl > $1.html
	touch .$1.plot
#	sleep 120
    fi
    shift
#    open $1.html
done
