#! /bin/bash
#SERVER=gnssplot.eng.trimble.com
#SERVER=192.168.250.139

E_NO_ARGS=65

USAGE="Usage: $0 TYPE PROJ Station Time_Zone_Offset GNSSFile1 GNSSFile2 .. GNSSFileN"

#print $#

if [ $# -le 4 ]  # Must have command-line args to demo script.
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

Local_TZ=$1
shift


if [ -f No_Voltage ]
then
    logger "Plot Voltages disbled in directory $PWD"
    exit 1
fi

# If the directory has a file No_Voltage then the Reciever doesn't support voltage records so stip the whole directory.

while (( "$#" )); do
    if [ ! -f .$1.volt ]
    then
    	echo "Plotting Voltage for" $1
	   logger "Plotting Voltage for $1"
       /mnt/GPS_Admin/cgi-bin/VoltagePlot/Plot_Voltage.sh $TYPE $PROJ $STATION $Local_TZ $1
#        curl  -F project=$TYPE -F Point=$STATION -F file=@$1 http://$SERVER/cgi-bin/PositionPlot/T02_2_PNG.pl > $1.html
	   touch .$1.volt
#	sleep 120
    else
    	echo "Skipping Plotting voltage for " $1
    fi
    shift
#    open $1.html
done
