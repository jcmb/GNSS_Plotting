#!/bin/bash
logger "AppFile for $1 $2"
logger `whereis viewdat`
#echo "start single $2****"
#echo $1 
cd /tmp
if [ -z "$2" ]
then    
    viewdat --appfile=$$.cfg $1 | grep -v "@trimble.com"
else
#    echo "single app file mode"
    viewdat --appfile=$$.cfg $1 >/dev/null
    cat $$.cfg
    rm $$.cfg
fi
rm $1
