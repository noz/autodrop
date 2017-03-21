#!/bin/sh

AUTODROP=/usr/local/sbin/autodrop
CONF=/etc/autodrop.conf
FIFO=/var/log/authfifo
PIDFILE=/var/run/autodrop.pid

case "$1" in
start)
    $AUTODROP --config="$CONF" --input="$FIFO" --pidfile="$PIDFILE"
    ;;
stop)
    kill -TERM `cat ${PIDFILE}`
    ;;
*)
    echo "usage: $0 { start | stop }" >&2
    exit 1
    ;;
esac
