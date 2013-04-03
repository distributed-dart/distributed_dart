#!/bin/bash

## start these processes 
run=(
    example/runme.dart 
)

basedir="$(readlink -f `dirname "$0"`/..)"
pidfile=/tmp/distributed_dart.pid
logfile=/tmp/distributed_dart.log
touch $pidfile
echo "kill running processes"
for pid in `cat $pidfile`; do 
    echo kill $pid
    kill $pid
done
> $pidfile

cd "$basedir" 
echo "start dart processes"
for f in ${run[@]}; do 
    if [ ! -f $f ]; then
        echo " > error: no such file, $f"
        continue
    fi
    echo " > $f"
    dart $f &>> $logfile &
    echo $! >> $pidfile
done
echo "done"
