#!/bin/sh
# Remet tous les containers dans un etat vierge.

find_container() {
    docker ps --format '{{.Names}}' | grep "throbert_$1-$2" | head -1
}

R1=$(find_container router 1)
R2=$(find_container router 2)
R3=$(find_container router 3)
R4=$(find_container router 4)
H1=$(find_container host 1)
H2=$(find_container host 2)
H3=$(find_container host 3)

clean_router() {
    CONTAINER=$1
    [ -z "$CONTAINER" ] && return
    echo "  clean $CONTAINER"
    docker exec "$CONTAINER" sh -c '
        ip link del vxlan10 2>/dev/null
        ip link del br0     2>/dev/null
        ip addr flush dev eth0 2>/dev/null
        ip addr flush dev eth1 2>/dev/null
        ip addr flush dev eth2 2>/dev/null
        ip addr flush dev lo   2>/dev/null
        vtysh -c "configure terminal
no router ospf
no router bgp 65000
end
write memory" 2>/dev/null
    '
}

clean_host() {
    CONTAINER=$1
    [ -z "$CONTAINER" ] && return
    echo "  clean $CONTAINER"
    docker exec "$CONTAINER" sh -c '
        ip addr flush dev eth0 2>/dev/null
    '
}

echo "=== Clean routers ==="
clean_router "$R4"
clean_router "$R1"
clean_router "$R2"
clean_router "$R3"

echo "=== Clean hosts ==="
clean_host "$H1"
clean_host "$H2"
clean_host "$H3"

echo ""
echo "Done. Tout est nettoye."
