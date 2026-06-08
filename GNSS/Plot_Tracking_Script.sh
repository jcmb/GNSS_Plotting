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

mkdir /tmp/Tracking 2>/dev/null

while (( "$#" )); do
    if [ ! -f .$1.track ]
    then
	echo "Plotting " $1
        ln -s $DIR/$1  /tmp/Tracking
	logger "/mnt/GPS_Admin/cgi-bin/TrackingPlot/plot_single_cgi.sh /tmp/Tracking/$1 $TYPE -1 $STATION -1 0 0/$PROJ -1"
        /mnt/GPS_Admin/cgi-bin/TrackingPlot/plot_single_cgi.sh /tmp/Tracking/$1 $TYPE 0 0 /$PROJ/$STATION
#        curl  -F project=$TYPE -F Point=$STATION -F file=@$1 http://$SERVER/cgi-bin/PositionPlot/T02_2_PNG.pl > $1.html
	touch .$1.track
#	sleep 120
    else
    	echo "Skipping Plotting " $1

    fi
    shift
#    open $1.html
done
