#!/bin/sh
# Usage: ./deploy_hosts.sh
# Configure les IPs sur les hosts apres les avoir demarre dans GNS3.

find_host() {
    docker ps --format '{{.Names}}' | grep "throbert_host-$1" | head -1
}

H1=$(find_host 1)
H2=$(find_host 2)
H3=$(find_host 3)

echo "Hosts detectes :"
echo "  Host 1 : ${H1:-INTROUVABLE}"
echo "  Host 2 : ${H2:-INTROUVABLE}"
echo "  Host 3 : ${H3:-INTROUVABLE}"
echo ""

deploy() {
    CONTAINER=$1
    SCRIPT=$2
    [ -z "$CONTAINER" ] && echo "  [SKIP] container introuvable pour $SCRIPT" && return
    echo "  -> $CONTAINER : $SCRIPT"
    docker cp "$SCRIPT" "$CONTAINER:/tmp/$SCRIPT"
    docker exec "$CONTAINER" sh "/tmp/$SCRIPT"
}

deploy "$H1" "throbert-1_host.sh"
deploy "$H2" "throbert-2_host.sh"
deploy "$H3" "throbert-3_host.sh"

echo ""
echo "Done. Hosts configures."
