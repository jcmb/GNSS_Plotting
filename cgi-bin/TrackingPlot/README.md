TrackingPlot
============

This is the series of scripts that are used on TrimbleTools and gnssplot for plotting Tracking information from T0x files.

In the **geoffrey-kirk---gnss-plotting** monorepo, sources live under `cgi-bin/TrackingPlot/` and the upload form is `HTML/T02_2_TRACKING.html`.

It creates static and interactive plots of the SNR's and cycle slips

External Requirements:
-------------

It requires ViewDat, which is a trimble internal tool :-(
gnuplot V5+ needs to be installed
Highcharts plotting needs to in installed in libraries on the web server
Python 3.6+

GitHub Modules
---------------
TZ.py needs to be installed on the path
WWW-common needs to be installed

Installation
------------

copy the files from www to a location on the web server
copy cgi-bin into cgi-bin/TrackingPlot on the web server, make all the files executable (chmod +x)
ensure antenna_common.js is deployed alongside the TrackingPlot pages (same directory as the .shtml files)
copy scripts/cleanup_data_results.sh to the server (for example /usr/local/lib/trackingplot/scripts/) and make it executable
install scripts/cleanup_data_results.cron on the server to run the cleanup daily (see the file for install notes)
copy scripts/cleanup_gnss_backup.sh to the server and make it executable
install scripts/cleanup_gnss_backup.cron on the server to run the GNSS backup cleanup daily (see the file for install notes)
