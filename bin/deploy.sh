#!/bin/bash

basedir="$(readlink -f `dirname "$0"`/..)"
pidfile=/tmp/distributed_dart.pid
logfile=/tmp/distributed_dart.log
run=(example/runme_one.dart example/runme_two.dart)

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
    $! >> $pidfile
done
echo "done"
