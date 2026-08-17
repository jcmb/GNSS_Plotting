#!/bin/bash

if [ $# -ne 1 ];
then
   echo $0
   echo Usage: $0 Tracking_Plot_Folder
   exit 254
fi

normalDir=`dirname $0`
#normalDir=`cd "${Dir}";pwd`
#echo $PATH
PATH=${normalDir}:$PATH
#echo $1
Name=`basename $1`
#echo $Name
Local_Time_Offset=`TZ.py`

echo "File Name, Band, SV Epochs with low SNR, SV Epochs, % with Low SNR"> Tracked.Bands.OUT

echo "<html><head>"
echo '<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css">'
echo "<title>Problem SV's for $Name</title>"
echo "</head>"

cat << EOF
<body class="page">
<div class="container clearfix">
  <div style="padding: 10px 10px 10px 0 ;"> <a href="/">
        <img src="/images/trimble-logo.jpg" alt="Trimble Logo" id="logo"> </a>
      </div>
  <!-- end #logo-area -->
</div>
<div id="top-header-trim"></div>
<div id="content-area">
<div id="content">
<div id="main-content">
EOF

echo "<h1>Low SNR SV's for $Name</h1><p/>"

while read p; do

   if [[ $p == GPS* ]] || [[ $p == GLONASS* ]]
   then
       if [[ $p == GLONASS-G3* ]]
       then
          echo "$p No Expected SNR's<br/>"
       else
          echo -e '<a href="#'$p'">'$p'</a><br/>'
       fi
   else
       echo "$p No Expected SNR's <br>"
   fi
done <Tracked.Bands

echo '<p/>'

while read p; do

   if [[ $p == GPS* ]] || [[ $p == GLONASS* ]]
   then
       if [[ $p == GLONASS-G3* ]]
       then
         true;
       else
          echo -e '<a name="'$p'"><h2>'$p'</h2>'
          echo -e '<h3>SVs with Low SNR</h3><img src="'$p'.OUT.png"><p/>'
          echo -e '<h3>Percentage of SVs with Low SNRs</h3><img src="'$p'.OUT-Percentage.png"><br/>'
          SNR_Warnings.py --Input $p.SNR --Output $p.OUT --Name $Name>>Tracked.Bands.OUT
          gnuplot -e "Local_Time_Offset=$Local_Time_Offset" -e "name='$Name'" -e "band='$p'" $normalDir/SNR_Warnings.plt&
       fi
   else
       true;
   fi

done <Tracked.Bands

awk -f $normalDir/Out2HTML.awk <Tracked.Bands.OUT >Low_SNRs_Table.html
echo "</body></html>"

wait
