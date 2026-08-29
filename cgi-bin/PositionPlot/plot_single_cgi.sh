#! /bin/bash

logger "Plot_single_cgi start $1 $2 $3 $4 $5 $6 $7 $8 $9"
logger `whoami`
#echo $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 "<br>"
# $upload_file,$extension,$Sol,$Point,$Ant,$Decimate,$Fixed_Range,$project,$SaveFile,$MeanSol,$ReportUrl;
#set -x

Ext=$2
SOL_REQUEST=$3
ALL_SOL_TYPES=0
Sol=""
case "$SOL_REQUEST" in
  -2)
    ALL_SOL_TYPES=1
    ;;
  -1|"")
    echo "Solution type is not filtered"
    ;;
  *)
    Sol="$SOL_REQUEST"
    ;;
esac
FileFull=`basename $1`;
File=`basename $1 $2`;
Dir=`dirname $0`;
normalDir=`cd "${Dir}";pwd`
#echo $PATH
PATH=${normalDir}:/usr/local/bin:~/bin:$PATH
Point=$4
Ant=$5
#TrimbleTools=$6
Decimate=$6
Fixed_Range=$7
Project=$8
SaveFile=$9
MeanSol=${10:-${GNSS_MEAN_SOL:--1}}
MEAN_SOL_REQUEST="$MeanSol"
ReportUrl=${11:-${GNSS_REPORT_URL:-/results/Position${Project}/${File}/}}
SESSION_REQUEST=${12:--1}
TRUTH_FILE=${13:-${GNSS_TRUTH_ATS:-}}
TRUTH_MODE=no
TRUTH_APPLIED=no
TRUTH_ATTEMPTED=no
if [ -n "$TRUTH_FILE" ] && [ -f "$TRUTH_FILE" ]
then
   TRUTH_MODE=yes
   TRUTH_ATTEMPTED=yes
fi
logger "Mean solution type request: $MEAN_SOL_REQUEST"
logger "Truth file: ${TRUTH_FILE:-none} (mode=$TRUTH_MODE)"
logger "Report URL: $ReportUrl"
logger "Session type request: $SESSION_REQUEST"

echo "Point $Point"
echo "Project $Project"

if [ ! $Point = -1 ]
then
   Project=$Project/$Point
fi
echo "Project $Project"
logger "Project $Project"

#export PATH
#echo "$FileFull<br>$File<br>"
#ls -l $1

. $normalDir/JCMBSoft_Config.sh
GNSS_CFG_DIR=`cd "$normalDir/../../admin/GNSS" 2>/dev/null && pwd`
if [ -z "$GNSS_CFG_DIR" ] || [ ! -f "$GNSS_CFG_DIR/GNSS_Paths.cfg" ]
then
   GNSS_CFG_DIR=/mnt/GPS_Admin/admin/GNSS
fi
if [ -f "$GNSS_CFG_DIR/GNSS_Paths.cfg" ]
then
   . "$GNSS_CFG_DIR/GNSS_Paths.cfg"
fi
if [ -z "$GNSS_RESULTS_DIR" ]
then
   GNSS_RESULTS_DIR=/mnt/Data/results
fi

RESULT_DIR="$GNSS_RESULTS_DIR/Position$Project/$File"
logger "$RESULT_DIR"
mkdir -p "$RESULT_DIR"
cd "$RESULT_DIR" && rm * 2> /dev/null
TMP_DIR=/run/shm/

logger `pwd`

echo Creating X29 file for $File
logger "Creating X29 file for $File"

viewdat -d29 --translate_rec35_sub2_to_rec29 -x -o$TMP_DIR$$.x29 $1

#viewdat -i -ofile.sum $1

#wait

rm $1

# Skipping creating the file
#   echo "Decimation interval: " $Decimate

if [ "$Decimate" = -1 ]
then
   echo "Computing decimation interval"
   eval $(compute_decimate.py $TMP_DIR$$.x29)
fi

if [ $Decimate = 0 ]
then
   echo "No Decimation"
   echo "All Data">Decimation
   tail -n +5 $TMP_DIR$$.x29 > $TMP_DIR$File.X29
else
   echo "Decimation interval: " $Decimate
   echo "Orginal interval: " $interval
   echo "Every: $Decimate (s), orginal ($interval)">Decimation
   echo Creating Decimated file for $File
   decimate.py $Decimate <$TMP_DIR$$.x29 > $TMP_DIR$File.X29
#   cp $1 $FileFull

fi

if [ "$SaveFile" = 1 ]
then
    mv $TMP_DIR$$.x29 $File.x29
    echo "<a href=\"$File.x29\">$File.x29<a/>">SaveFile.html

else
    rm $TMP_DIR$$.x29
    echo "Not Saved">SaveFile.html
fi


echo "$File" >file.html

#echo "Solution Type $Sol";

echo "Checking database for $Point"

#$normalDir/GNSS_TRUTH.py $Point

eval $($normalDir/GNSS_TRUTH.py $Point)

# Truth DB may return Solution — use it only when a specific type was requested
PLOT_FILTER_SOL=""
case "$SOL_REQUEST" in
  -2|-1|"")
    Sol=""
    PLOT_FILTER_SOL=""
    ;;
  *)
    Sol="$SOL_REQUEST"
    PLOT_FILTER_SOL="$SOL_REQUEST"
    ;;
esac

if [ "$ALL_SOL_TYPES" = "1" ]
then
   Sol_Name="All Types"
   Sol_HRange=5
   Sol_VRange=10
   Sol_Latency=0
   Sol_3DRange=10
   PLOT_FILTER_SOL=""
elif [ -n "$PLOT_FILTER_SOL" ]
then
   eval $(original-awk -f $normalDir/x29_sol_type.awk $PLOT_FILTER_SOL < $TMP_DIR$File.X29);
else
   eval $(original-awk -f $normalDir/x29_sol_type.awk < $TMP_DIR$File.X29);
   Sol=""
fi
echo "Solution Type $Sol_Name ($Sol)";

PLOT_SOL="$Sol"
PLOT_SOL_NAME="$Sol_Name"
PLOT_HRANGE="$Sol_HRange"
PLOT_VRANGE="$Sol_VRange"
PLOT_LATENCY="$Sol_Latency"
PLOT_3DRANGE="$Sol_3DRange"

MEAN_SOL=""
MEAN_SOL_NAME=""
case "$MEAN_SOL_REQUEST" in
  -1|"")
    eval $(original-awk -f $normalDir/x29_sol_type.awk < $TMP_DIR$File.X29)
    MEAN_SOL="$Sol"
    MEAN_SOL_NAME="$Sol_Name"
    ;;
  all)
    MEAN_SOL="all"
    MEAN_SOL_NAME="All Types"
    ;;
  *)
    MEAN_SOL="$MEAN_SOL_REQUEST"
    eval $(original-awk -f $normalDir/x29_sol_type.awk $MEAN_SOL_REQUEST < $TMP_DIR$File.X29)
    MEAN_SOL_NAME="$Sol_Name"
    ;;
esac

Sol="$PLOT_SOL"
Sol_Name="$PLOT_SOL_NAME"
Sol_HRange="$PLOT_HRANGE"
Sol_VRange="$PLOT_VRANGE"
Sol_Latency="$PLOT_LATENCY"
Sol_3DRange="$PLOT_3DRANGE"
if [ -z "$MEAN_SOL" ] || [ "$MEAN_SOL" = "-1" ]
then
   MEAN_SOL="all"
   MEAN_SOL_NAME="All Types"
fi
echo "Mean from solution type $MEAN_SOL_NAME ($MEAN_SOL)";

if [ "$Lat" == "" ]
then
    eval $(original-awk -f $normalDir/x29_mean2.awk $MEAN_SOL <$TMP_DIR$File.X29)
    original-awk -f $normalDir/llh_mean_report.awk \
        -v mode=computed \
        -v label="$MEAN_SOL_NAME (type $MEAN_SOL)" \
        -v lat="$Lat" -v lon="$Long" -v height="$Height" \
        -v records="$Records" \
        -v lat_std="${Lat_Std:-0}" -v lon_std="${Long_Std:-0}" -v height_std="${Height_Std:-0}" \
        > llh.mean

else
    original-awk -f $normalDir/llh_mean_report.awk \
        -v mode=database \
        -v lat="$Lat" -v lon="$Long" -v height="$Height" \
        > llh.mean
fi

echo "Latitude $Lat"
echo "Longitude $Long"
echo "Height $Height"
echo "Records $Records"


$normalDir/kml_point.py $File $Lat $Long $Height

echo "</pre>"
echo "<a href=\"$File.kml\">$File.kml</a>"
echo "<a href=\"$File.kml\">$File.kml</a>">kml.html
echo "<pre>"


if [ -n "$PLOT_FILTER_SOL" ]
then
   original-awk -f $normalDir/x29_sum.awk $PLOT_FILTER_SOL <$TMP_DIR$File.X29 | tee sum.txt
else
   original-awk -f $normalDir/x29_sum.awk <$TMP_DIR$File.X29 | tee sum.txt
fi

if [ -n "$PLOT_FILTER_SOL" ]
then
   original-awk -f $normalDir/x29_sol.awk $PLOT_FILTER_SOL <$TMP_DIR$File.X29 >$File.sol
   rm $TMP_DIR$File.X29
else
   mv $TMP_DIR$File.X29 $File.sol
fi

POINT_FROM_DB=0
if [ "$Point" != "-1" ] && [ -n "$Lat" ]
then
   POINT_FROM_DB=1
fi

enu_filter_stream() {
  local _src="$1"
  if [ "$MEAN_SOL" = "all" ]; then
    cat "$_src"
  else
    original-awk -F, -v sol="$MEAN_SOL" '($9 + 0) == (sol + 0)' "$_src"
  fi
}

SESSION_USED="static"
SESSION_DETECTED="static"
DETECTION_RAN="no"
OUTLIER_FRACTION="0"
OUTLIER_COUNT="0"
VALID_COUNT="0"
DRIVE_WARNING="no"

_run_motion_detect() {
  enu_filter_stream "$File.enu.provisional" | $normalDir/detect_motion.py
}

detect_session_type() {
echo "Computing provisional ENU for session detection"
original-awk -f $normalDir/x29_enu.awk $File.sol $Lat $Long $Height >$File.enu.provisional

case "$SESSION_REQUEST" in
  1|moving)
    SESSION_USED="moving"
    ;;
  0|static)
    SESSION_USED="static"
    if [ "$POINT_FROM_DB" != "1" ]
    then
       DETECTION_RAN="yes"
       while IFS= read -r _det_line
       do
          case "$_det_line" in
             detected:*) SESSION_DETECTED="${_det_line#detected: }" ;;
             outlier_fraction:*) OUTLIER_FRACTION="${_det_line#outlier_fraction: }" ;;
             outlier_count:*) OUTLIER_COUNT="${_det_line#outlier_count: }" ;;
             valid_count:*) VALID_COUNT="${_det_line#valid_count: }" ;;
          esac
       done < <(_run_motion_detect)
       if [ "$SESSION_DETECTED" = "moving" ]
       then
          DRIVE_WARNING="yes"
       fi
    fi
    ;;
  *)
    if [ "$POINT_FROM_DB" = "1" ]
    then
       SESSION_USED="static"
    else
       DETECTION_RAN="yes"
       while IFS= read -r _det_line
       do
          case "$_det_line" in
             detected:*) SESSION_DETECTED="${_det_line#detected: }"; SESSION_USED="${_det_line#detected: }" ;;
             outlier_fraction:*) OUTLIER_FRACTION="${_det_line#outlier_fraction: }" ;;
             outlier_count:*) OUTLIER_COUNT="${_det_line#outlier_count: }" ;;
             valid_count:*) VALID_COUNT="${_det_line#valid_count: }" ;;
          esac
       done < <(_run_motion_detect)
    fi
    ;;
esac
}

write_session_type_txt() {
case "$SESSION_REQUEST" in
  -1|""|auto)
    SESSION_REQUEST_LABEL="Automatic"
    ;;
  0|static)
    SESSION_REQUEST_LABEL="Static"
    ;;
  1|moving)
    SESSION_REQUEST_LABEL="Moving"
    ;;
  *)
    SESSION_REQUEST_LABEL="$SESSION_REQUEST"
    ;;
esac

{
echo "Session requested: $SESSION_REQUEST_LABEL"
echo "Session used: $SESSION_USED"
if [ "$TRUTH_APPLIED" = "yes" ]
then
   echo "ATS truth file: yes ($(basename "$TRUTH_FILE")) — applied"
elif [ "$TRUTH_ATTEMPTED" = "yes" ]
then
   echo "ATS truth file: yes ($(basename "$TRUTH_FILE")) — not used (no GNSS overlap)"
else
   echo "ATS truth file: no"
fi
if [ "$TRUTH_ATTEMPTED" = "yes" ]
then
   echo "ATS filename: $(basename "$TRUTH_FILE")"
fi
echo "Detection ran: $DETECTION_RAN"
echo "Outlier fraction: ${OUTLIER_FRACTION}% (>10 sigma, 2D)"
echo "Outlier epochs: $OUTLIER_COUNT / $VALID_COUNT"
echo "Drive test warning: $DRIVE_WARNING"
} > session_type.txt
}

if [ "$TRUTH_MODE" = "yes" ]
then
   echo "ATS truth file provided — attempting truth-referenced errors"
   logger "Attempting ATS truth alignment for $FileFull"

   TRUTH_SOL_ARGS=""
   if [ "$MEAN_SOL" != "all" ] && [ -n "$MEAN_SOL" ]
   then
      TRUTH_SOL_ARGS="--sol-type $MEAN_SOL"
   fi

   if $normalDir/truth_gnss_enu.py --ats "$TRUTH_FILE" --sol "$File.sol" \
        --out "$File.enu" --report truth_report.txt $TRUTH_SOL_ARGS
   then
      TRUTH_APPLIED=yes
      SESSION_USED="moving"
      SESSION_DETECTED="moving"
   else
      _truth_exit=$?
      echo "WARNING: ATS truth alignment failed (exit $_truth_exit) — processing as normal"
      logger "ATS truth fallback to normal processing for $FileFull (exit $_truth_exit)"
      TRUTH_MODE=no
      TRUTH_APPLIED=no
      detect_session_type
   fi
else
   detect_session_type
fi

write_session_type_txt

if [ "$TRUTH_APPLIED" = "yes" ]
then
   echo "ATS truth session — ENU errors vs interpolated truth"
   logger "ATS truth session for $FileFull"

   $normalDir/kml_trajectory.py $File $File.sol
   echo "<a href=\"$File.kml\">$File.kml</a>">kml.html

   {
   echo "ATS file: $(basename "$TRUTH_FILE")"
   cat truth_report.txt
   } > truth_report.tmp && mv truth_report.tmp truth_report.txt

   {
   echo "TRAJECTORY_SESSION"
   echo "Moving session with ATS truth reference."
   cat truth_report.txt
   } > llh.mean

   echo ""
   echo "Computing session time range"
   $normalDir/time_range_report.py <$File.enu >time_range.txt

   echo ""
   echo "Computing NEE Mean"
   eval $(original-awk -f $normalDir/x29_mean2_enu.awk $MEAN_SOL $Sol_HRange $Sol_VRange $Fixed_Range <$File.enu)

   rm -f $File.enu.provisional $File.sol
elif [ "$SESSION_USED" = "moving" ]
then
   echo "Moving session — using trajectory (LLH) data"
   logger "Moving session for $FileFull"

   $normalDir/trajectory_summary.py <$File.sol | tee trajectory_summary.txt

   {
   echo "TRAJECTORY_SESSION"
   echo "Moving session — no fixed reference position."
   cat trajectory_summary.txt
   } > llh.mean

   $normalDir/kml_trajectory.py $File $File.sol
   echo "<a href=\"$File.kml\">$File.kml</a>">kml.html

   echo ""
   echo "Computing session time range"
   $normalDir/time_range_report.py <$File.sol >time_range.txt

   echo "Session: moving" | tee nee.mean
   cat trajectory_summary.txt | tee -a nee.mean

   cp $File.sol $File.trajectory
   rm -f $File.enu.provisional $File.sol
else
   echo "Static session — ENU errors vs reference"
   logger "Static session for $FileFull"

   mv $File.enu.provisional $File.enu

   echo ""
   echo "Computing session time range"
   $normalDir/time_range_report.py <$File.enu >time_range.txt

   echo ""
   echo "Computing NEE Mean"
   eval $(original-awk -f $normalDir/x29_mean2_enu.awk $MEAN_SOL $Sol_HRange $Sol_VRange $Fixed_Range <$File.enu)

   rm -f $File.sol
fi

{
echo "Mean / reference computation"
echo "=========================="
if grep -q "ATS truth" llh.mean 2>/dev/null
then
   echo "Reference LLH: ATS truth trajectory"
elif grep -q "From Database" llh.mean 2>/dev/null
then
   echo "Reference LLH: Point database"
else
   echo "Reference LLH: Computed from file"
fi
case "$MEAN_SOL_REQUEST" in
  -1|"")
    echo "Mean type requested: Automatic"
    ;;
  all)
    echo "Mean type requested: All (no filter)"
    ;;
  *)
    echo "Mean type requested: $MEAN_SOL_NAME (type $MEAN_SOL_REQUEST)"
    ;;
esac
if [ "$MEAN_SOL" = "all" ]
then
   echo "Mean type used: All types (all records)"
else
   echo "Mean type used: $MEAN_SOL_NAME (type $MEAN_SOL)"
fi
echo "Records in mean: $Records"
echo "Session used: $SESSION_USED"
} > mean.info

if [ "$SESSION_USED" != "moving" ] || [ "$TRUTH_APPLIED" = "yes" ]
then
enu_cdf_stream() {
  if [ "$MEAN_SOL" = "all" ]; then
    cat "$File.enu"
  else
    original-awk -F, -v sol="$MEAN_SOL" '($9 + 0) == (sol + 0)' "$File.enu"
  fi
}

_cdf_records=$(enu_cdf_stream | wc -l | tr -d ' ')

if [ -z "$_cdf_records" ] || [ "$_cdf_records" -lt 1 ] 2>/dev/null
then
   north_cdf_68=0
   north_cdf_95=0
   east_cdf_68=0
   east_cdf_95=0
   cdf_68=0
   cdf_95=0
   north_sigma_cdf_68=0
   north_sigma_cdf_95=0
   east_sigma_cdf_68=0
   east_sigma_cdf_95=0
   sigma_cdf_68=0
   sigma_cdf_95=0
else
   _north_cdf=$(enu_cdf_stream | original-awk -f $normalDir/x29_height_abs.awk 11 | sort --field-separator=, --numeric-sort --key=11 | original-awk -f $normalDir/x29_height_cdf.awk "$_cdf_records" 11)
   case "$_north_cdf" in
      cdf_68=*|*) eval "$_north_cdf"; north_cdf_68=$cdf_68; north_cdf_95=$cdf_95 ;;
      *) north_cdf_68=0; north_cdf_95=0 ;;
   esac
   _east_cdf=$(enu_cdf_stream | original-awk -f $normalDir/x29_height_abs.awk 12 | sort --field-separator=, --numeric-sort --key=12 | original-awk -f $normalDir/x29_height_cdf.awk "$_cdf_records" 12)
   case "$_east_cdf" in
      cdf_68=*|*) eval "$_east_cdf"; east_cdf_68=$cdf_68; east_cdf_95=$cdf_95 ;;
      *) east_cdf_68=0; east_cdf_95=0 ;;
   esac
   _height_cdf=$(enu_cdf_stream | original-awk -f $normalDir/x29_height_abs.awk 13 | sort --field-separator=, --numeric-sort --key=13 | original-awk -f $normalDir/x29_height_cdf.awk "$_cdf_records" 13)
   case "$_height_cdf" in
      cdf_68=*|*) eval "$_height_cdf" ;;
      *) cdf_68=0; cdf_95=0 ;;
   esac
   _north_sigma_cdf=$(enu_cdf_stream | original-awk -f $normalDir/x29_sigma.awk n | sort --field-separator=, --numeric-sort --key=25 | original-awk -f $normalDir/x29_sigma_cdf.awk "$_cdf_records")
   case "$_north_sigma_cdf" in
      sigma_cdf_68=*|*) eval "$_north_sigma_cdf"; north_sigma_cdf_68=$sigma_cdf_68; north_sigma_cdf_95=$sigma_cdf_95 ;;
      *) north_sigma_cdf_68=0; north_sigma_cdf_95=0 ;;
   esac
   _east_sigma_cdf=$(enu_cdf_stream | original-awk -f $normalDir/x29_sigma.awk e | sort --field-separator=, --numeric-sort --key=25 | original-awk -f $normalDir/x29_sigma_cdf.awk "$_cdf_records")
   case "$_east_sigma_cdf" in
      sigma_cdf_68=*|*) eval "$_east_sigma_cdf"; east_sigma_cdf_68=$sigma_cdf_68; east_sigma_cdf_95=$sigma_cdf_95 ;;
      *) east_sigma_cdf_68=0; east_sigma_cdf_95=0 ;;
   esac
   _sigma_cdf=$(enu_cdf_stream | original-awk -f $normalDir/x29_sigma.awk u | sort --field-separator=, --numeric-sort --key=25 | original-awk -f $normalDir/x29_sigma_cdf.awk "$_cdf_records")
   case "$_sigma_cdf" in
      sigma_cdf_68=*|*) eval "$_sigma_cdf" ;;
      *) sigma_cdf_68=0; sigma_cdf_95=0 ;;
   esac
fi

echo "North: $North" | tee  nee.mean
echo "North Min: $North_Min" | tee  -a nee.mean
echo "North Max: $North_Max" | tee  -a nee.mean
echo "North Range: $North_Range" | tee  -a nee.mean
echo "North 68%: $north_cdf_68" | tee -a nee.mean
echo "North 95%: $north_cdf_95" | tee -a nee.mean
echo ""| tee -a nee.mean
echo "East: $East" | tee -a nee.mean
echo "East Min: $East_Min" | tee  -a nee.mean
echo "East Max: $East_Max" | tee  -a nee.mean
echo "East Range: $East_Range" | tee  -a nee.mean
echo "East 68%: $east_cdf_68" | tee -a nee.mean
echo "East 95%: $east_cdf_95" | tee -a nee.mean
echo ""| tee -a nee.mean
echo "Elev: $Elev" | tee -a nee.mean
echo "Elev Min: $Elev_Min" | tee  -a nee.mean
echo "Elev Max: $Elev_Max" | tee  -a nee.mean
echo "Elev Range: $Elev_Range" | tee  -a nee.mean
echo "Elev 68%: $cdf_68" | tee  -a nee.mean
echo "Elev 95%: $cdf_95" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "North Sigma 68%: $north_sigma_cdf_68" | tee -a nee.mean
echo "North Sigma 95%: $north_sigma_cdf_95" | tee -a nee.mean
echo "East Sigma 68%: $east_sigma_cdf_68" | tee -a nee.mean
echo "East Sigma 95%: $east_sigma_cdf_95" | tee -a nee.mean
echo "Elev Sigma 68%: $sigma_cdf_68" | tee  -a nee.mean
echo "Elev Sigma 95%: $sigma_cdf_95" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "Fixed Range: $Fixed_Range"  | tee  -a nee.mean
echo "Horizontal Range for plotting $Sol_HRange"  | tee  -a nee.mean
echo "Vertical Range for plotting $Sol_VRange"  | tee  -a nee.mean
echo "3D Range: $Sol_3DRange" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "Records: $Records" | tee -a nee.mean
echo "Mean Solution Type: $MEAN_SOL_NAME ($MEAN_SOL)" | tee -a nee.mean
echo ""| tee -a nee.mean
fi


echo Generating interactive plot data for $FileFull
logger "Generating interactive plot data for $FileFull"

echo "$FileFull" >file.html

_write_plot_filter() {
   if [ "$ALL_SOL_TYPES" = "1" ]; then
      echo "all" > plot_filter.txt
   elif [ -n "$PLOT_FILTER_SOL" ]; then
      echo "type:$PLOT_FILTER_SOL" > plot_filter.txt
   else
      echo "none" > plot_filter.txt
   fi
   echo "mean:$MEAN_SOL" >> plot_filter.txt
   echo "mean_name:$MEAN_SOL_NAME" >> plot_filter.txt
   echo "mean_request:$MEAN_SOL_REQUEST" >> plot_filter.txt
   echo "session:$SESSION_USED" >> plot_filter.txt
   echo "session_request:$SESSION_REQUEST" >> plot_filter.txt
   echo "drive_warning:$DRIVE_WARNING" >> plot_filter.txt
   if [ "$TRUTH_APPLIED" = "yes" ]
   then
      echo "truth:yes" >> plot_filter.txt
      if [ -f truth_report.txt ]
      then
         grep '^truth_height_offset:' truth_report.txt >> plot_filter.txt || true
      fi
   else
      echo "truth:no" >> plot_filter.txt
   fi
}

if [ "$TRUTH_APPLIED" = "yes" ]
then
   cp $File.enu file
   cp file position_solution.csv
   $normalDir/x29_secs.py < file > position_data.csv
   _write_plot_filter
   gzip -9 -f position_data.csv position_solution.csv

   $normalDir/out_range.py -R 0.0105 < file --OUTAGE outage1cm.csv --DETAIL /dev/null --SUMMARY range1cm.sum
   $normalDir/out_range.py -R 0.0205 < file --OUTAGE outage2cm.csv --DETAIL /dev/null --SUMMARY range2cm.sum
   $normalDir/out_range.py -R 0.0305 < file --OUTAGE outage2sig.csv --DETAIL range2sig.csv --SUMMARY range2sig.sum
   $normalDir/out_range.py -R 0.0455 < file --OUTAGE outage3sig.csv --DETAIL range3sig.csv --SUMMARY range3sig.sum

   range_1cm=`$normalDir/range_summary.pl <range1cm.sum`
   range_2cm=`$normalDir/range_summary.pl <range2cm.sum`
   range_2_sigma=`$normalDir/range_summary.pl <range2sig.sum`
   range_3_sigma=`$normalDir/range_summary.pl <range3sig.sum`
   echo -n "$File," > $File.sum.csv
   echo -n "$Elev_Range," >> $File.sum.csv
   echo -n "$cdf_68," >> $File.sum.csv
   echo -n "$cdf_95," >> $File.sum.csv
   echo -n "$sigma_cdf_68," >> $File.sum.csv
   echo -n "$sigma_cdf_95," >> $File.sum.csv
   echo -n "$range_1cm," >> $File.sum.csv
   echo -n "$range_2cm," >> $File.sum.csv
   echo -n "$range_2_sigma," >> $File.sum.csv
   echo  "$range_3_sigma" >> $File.sum.csv
   rm file
elif [ "$SESSION_USED" = "moving" ]
then
   $normalDir/x29_secs.py <$File.trajectory > position_data.csv
   cp $File.trajectory position_solution.csv
   rm -f $File.trajectory
   _write_plot_filter
   gzip -9 -f position_data.csv position_solution.csv
   echo -n "$File,moving" > $File.sum.csv
else
#cp $normalDir/plot_index.html index.shtml
mv $File.enu file
cp file position_solution.csv
$normalDir/x29_secs.py < file > position_data.csv
_write_plot_filter
gzip -9 -f position_data.csv position_solution.csv

$normalDir/out_range.py -R 0.0105 < file --OUTAGE outage1cm.csv --DETAIL /dev/null --SUMMARY range1cm.sum
$normalDir/out_range.py -R 0.0205 < file --OUTAGE outage2cm.csv --DETAIL /dev/null --SUMMARY range2cm.sum
$normalDir/out_range.py -R 0.0305 < file --OUTAGE outage2sig.csv --DETAIL range2sig.csv --SUMMARY range2sig.sum
$normalDir/out_range.py -R 0.0455 < file --OUTAGE outage3sig.csv --DETAIL range3sig.csv --SUMMARY range3sig.sum

range_1cm=`$normalDir/range_summary.pl <range1cm.sum`
range_2cm=`$normalDir/range_summary.pl <range2cm.sum`
range_2_sigma=`$normalDir/range_summary.pl <range2sig.sum`
range_3_sigma=`$normalDir/range_summary.pl <range3sig.sum`
echo -n "$File," > $File.sum.csv
echo -n "$Elev_Range," >> $File.sum.csv
echo -n "$cdf_68," >> $File.sum.csv
echo -n "$cdf_95," >> $File.sum.csv
echo -n "$sigma_cdf_68," >> $File.sum.csv
echo -n "$sigma_cdf_95," >> $File.sum.csv
echo -n "$range_1cm," >> $File.sum.csv
echo -n "$range_2cm," >> $File.sum.csv
echo -n "$range_2_sigma," >> $File.sum.csv
echo  "$range_3_sigma" >> $File.sum.csv
rm file
fi

echo "<a href=\"$File.sum.csv\">$File.sum.csv</a>">sum.html

#wait
#rm file
echo '</pre>'
#echo -n '<base href="http://trimbletools.com/results/Position/'
#echo -n $File
#echo '/" />'
ln -sf $normalDir/index.shtml .
ln -sf $normalDir/interactive_plot.js
ln -sf $normalDir/report_tables.js
rm outage1cm.csv
rm outage2cm.csv
rm outage2sig.csv
rm outage3sig.csv
#rm range1cm.csv
#rm range2cm.csv
rm -f range2sig.csv range3sig.csv
wait
echo Processing completed
echo "<p><strong>Processing complete.</strong></p>"
echo "<p><a href=\"${ReportUrl}\">Open report</a> (redirecting&hellip;)</p>"
echo "<meta http-equiv=\"refresh\" content=\"0;url=${ReportUrl}\">"
echo "<script>window.location.replace(\"${ReportUrl}\");</script>"
echo "</body></html>"
logger "Plot_single_cgi finished $1 * $2 * $3 * $4 * $5 * $6 *  $7 * $8"
