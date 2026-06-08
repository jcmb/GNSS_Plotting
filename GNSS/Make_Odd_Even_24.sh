#! /bin/bash
exit
shopt -s nullglob

if [ ! -z $2 ]
then
   mkdir -p $2
   cd $2
fi

mkdir -p ODD
mkdir -p EVEN

for f in *[13579].$1
do
#   if [ 1 ]
   if [ ! -e ODD/$f ]
   then
#       rm /Volumes/GPS_MYSQL/GPS_Data/$3/$DIR/$2/ODD/$f
       ln $f ODD/$f
   fi
done

for f in *[02468].$1
do
#   if [ 1 ]
   if [ ! -e EVEN/$f ]
   then
#       rm /Volumes/GPS_MYSQL/GPS_Data/$3/$DIR/$2/EVEN/$f
       ln $f EVEN/$f
   fi
done
