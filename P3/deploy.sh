#!/bin/sh
# Usage: ./deploy.sh
# Copie et execute les configs sur les containers GNS3 du projet P3.
# Les containers doivent etre demarres dans GNS3 avant de lancer ce script.

find_router() {
    docker ps --format '{{.Names}}' | grep "throbert_router-$1" | head -1
}
find_host() {
    docker ps --format '{{.Names}}' | grep "throbert_host-$1" | head -1
}

R1=$(find_router 1)
R2=$(find_router 2)
R3=$(find_router 3)
R4=$(find_router 4)
H1=$(find_host 1)
H2=$(find_host 2)
H3=$(find_host 3)

echo "Containers detectes :"
echo "  Routeur 1 (VTEP)  : ${R1:-INTROUVABLE}"
echo "  Routeur 2 (VTEP)  : ${R2:-INTROUVABLE}"
echo "  Routeur 3 (VTEP)  : ${R3:-INTROUVABLE}"
echo "  Routeur 4 (RR)    : ${R4:-INTROUVABLE}"
echo "  Host 1            : ${H1:-INTROUVABLE}"
echo "  Host 2            : ${H2:-INTROUVABLE}"
echo "  Host 3            : ${H3:-INTROUVABLE}"
echo ""

if [ -z "$R1" ] || [ -z "$R2" ] || [ -z "$R3" ] || [ -z "$R4" ]; then
    echo "Erreur: routeurs introuvables. Verifie que GNS3 est lance."
    exit 1
fi

deploy() {
    CONTAINER=$1
    SCRIPT=$2
    [ -z "$CONTAINER" ] && echo "  [SKIP] container introuvable pour $SCRIPT" && return
    echo "  -> $CONTAINER : $SCRIPT"
    docker cp "$SCRIPT" "$CONTAINER:/tmp/$SCRIPT"
    docker exec "$CONTAINER" sh "/tmp/$SCRIPT"
}

# RR en premier pour qu'il soit pret quand les VTEP essaient de se connecter
deploy "$R4" "throbert-4-routeur.sh"
deploy "$R1" "throbert-1-routeur.sh"
deploy "$R2" "throbert-2-routeur.sh"
deploy "$R3" "throbert-3-routeur.sh"

echo ""
echo "Done. Routers configures."
echo "Verifie avec : docker exec <routeur> vtysh -c 'show bgp l2vpn evpn'"
echo "Pour configurer les hosts : ./deploy_hosts.sh"
