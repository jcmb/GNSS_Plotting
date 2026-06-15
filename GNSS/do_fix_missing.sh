#!/bin/bash

PATH=/usr/local/bin:$PATH

shopt -s nullglob
logger  "do_fix_missing.sh started"

echo "Processing BTN 1 hour files"


cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/BTN_Base && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/BTN_Base_450 && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/East && Fix_Missing_24.py T04

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/I25 && Fix_Missing_24.py T04

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/I25_South && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/Jam && Fix_Missing_24.py T04

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/Mid_North && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/Middle && Fix_Missing_24.py T04

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/NNW && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/North && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/NW && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/SE && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/South && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/SW && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/TANK && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/Tree && Fix_Missing_24.py T02

cd /Volumes/GPS_MYSQL/GPS_Data/BTN/1_HOUR/West && Fix_Missing_24.py T02


logger  "do_fix_missing.sh finished"
