#!/bin/sh

mkdir -p /var/run/frr /var/log/frr
chown -R frr:frr /var/run/frr /var/log/frr

/usr/lib/frr/frrinit.sh start

exec "$@"
