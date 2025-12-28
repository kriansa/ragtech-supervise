#!/usr/bin/env bash

mkdir /opt/supervise/log
touch /opt/supervise/log/supsvc.log /opt/supervise/log/device.log /opt/supervise/log/serialhid.log

# Set the monit DB to WAL to allow concurrent readers
sqlite3 /opt/supervise/monit.db "PRAGMA journal_mode=WAL" >/dev/null

# Setup the database in the data directory
ln -sf /data/monit.db /opt/supervise/monit.db
ln -sf /data/monit.db-wal /opt/supervise/monit.db-wal
ln -sf /data/monit.db-shm /opt/supervise/monit.db-shm

# This process will fork if their parent is not PID 1
# We also tag their log lines with `main` so it doesn't get confused with the other log streams
echo "[init] starting supsvc"
/opt/supervise/supsvc 2>&1 | sed 's/^/\[main\] /' & main=$!

# Tail all output log streams with their respective tag
echo "[init] starting log streams"
tail -f /opt/supervise/log/supsvc.log | sed 's/^/\[supsvc\] /' &
tail -f /opt/supervise/log/device.log | sed 's/^/\[device-manager\] /' &
tail -f /opt/supervise/log/serialhid.log | sed 's/^/\[serialhid\] /' &

# Then make sure we capture signals and forward them to the child processes
trap exit EXIT

# We wait for the main process to exit, then we kill all the other processes
wait $main; retcode=$?
echo "[init] supsvc process terminated, status code: $retcode"
jobs -p | xargs --no-run-if-empty -- kill
wait
exit $retcode
