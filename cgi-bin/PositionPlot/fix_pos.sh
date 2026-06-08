#! /bin/bash

Dir=`dirname $0`;
normalDir=`cd "${Dir}";pwd`

if [ ! -f file.org ]
then
    mv file file.org
    $normalDir/x29_secs.py <file.org >file
fi

$normalDir/gnuplot file.plt $normalDir/X29_plot.plt
$normalDir/out_range.py -R 0.0305 < file --OUTAGE outage2.csv --DETAIL range2.csv --SUMMARY range2.sum
$normalDir/out_range.py -R 0.0455 < file --OUTAGE outage3.csv --DETAIL range3.csv --SUMMARY range3.sum
$normalDir/gnuplot file.plt $normalDir/range.plt
$normalDir/gnuplot file.plt $normalDir/range_hist.plt
