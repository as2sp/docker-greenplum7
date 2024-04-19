#!/bin/bash

set -e

/etc/init.d/ssh start
sleep 1

su - gpadmin -c 'gpstart -a'

stop_greenplum() {
    su - gpadmin -c 'gpstop -a -M fast'
}

trap stop_greenplum INT TERM

tail -f $(ls /data/master/gpsne-1/pg_log/gpdb-* | tail -n1) &

wait
