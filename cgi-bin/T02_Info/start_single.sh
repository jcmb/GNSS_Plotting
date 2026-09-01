#!/bin/bash
logger "Information for $1"
logger `whereis viewdat`

viewdat -i $1
viewdat -d12,16:3,16:27,16:43,24 $1
rm $1
