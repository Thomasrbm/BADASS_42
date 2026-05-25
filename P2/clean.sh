#!/bin/sh


R1=$(docker ps --format '{{.Names}}' | grep "throbert_router-1" | head -1)
R2=$(docker ps --format '{{.Names}}' | grep "throbert_router-2" | head -1)

if [ -z "$R1" ] || [ -z "$R2" ]; then
    echo "Erreur: routeurs introuvables. Verifie que GNS3 est lance."
    exit 1
fi

CLEAN='
ip link set vxlan10 nomaster  2>/dev/null
ip link set eth1    nomaster  2>/dev/null
ip link set vxlan10 down      2>/dev/null
ip link delete vxlan10        2>/dev/null
ip link set br0 down          2>/dev/null
ip link delete br0            2>/dev/null
ip addr flush dev eth0        2>/dev/null
ip link set eth0 down         2>/dev/null
'

echo "Clean $R1..."
docker exec "$R1" sh -c "$CLEAN"

echo "Clean $R2..."
docker exec "$R2" sh -c "$CLEAN"

echo "Done. Lance ./deploy.sh [static|multi]"
