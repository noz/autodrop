#!/bin/sh

AUTODROP=/usr/local/sbin/autodrop
CONF=/etc/autodrop.conf
PIDFILE=/var/run/autodrop.pid

case "$1" in
    start)
	$AUTODROP -c $CONF
	;;
    stop)
	kill -TERM `cat ${PIDFILE}`
	;;
    *)
	echo "usage: $0 { start | stop }" >&2
	exit 1
	;;
esac
