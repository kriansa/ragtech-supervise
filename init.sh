#!/usr/bin/env bash

mkdir /opt/supervise/log
touch /opt/supervise/log/supsvc.log /opt/supervise/log/device.log /opt/supervise/log/serialhid.log

# Setup the database in the data directory
ln -sf /data/monit.db /opt/supervise/monit.db
ln -sf /data/monit.db-wal /opt/supervise/monit.db-wal
ln -sf /data/monit.db-shm /opt/supervise/monit.db-shm

# Set the monit DB to WAL to allow concurrent readers
sqlite3 /data/monit.db "PRAGMA journal_mode=WAL" >/dev/null

# This process will fork if their parent is not PID 1
# We also tag their log lines with `main` so it doesn't get confused with the other log streams
/opt/supervise/supsvc 2>&1 | sed 's/^/\[main\] /' &

# Tail all output log streams with their respective tag
tail -f /opt/supervise/log/supsvc.log | sed 's/^/\[supsvc\] /' &
tail -f /opt/supervise/log/device.log | sed 's/^/\[device-manager\] /' &
tail -f /opt/supervise/log/serialhid.log | sed 's/^/\[serialhid\] /' &

# Then make sure we capture signals and forward them to the child processes
trap exit EXIT
wait
