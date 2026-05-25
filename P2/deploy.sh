#!/bin/sh

MODE=${1:-static}

if [ "$MODE" != "static" ] && [ "$MODE" != "multi" ]; then
    echo "Usage: $0 [static|multi]"
    exit 1
fi

R1=$(docker ps --format '{{.Names}}' | grep "throbert_router-1" | head -1)
R2=$(docker ps --format '{{.Names}}' | grep "throbert_router-2" | head -1)
H1=$(docker ps --format '{{.Names}}' | grep "throbert_host-1"   | head -1)
H2=$(docker ps --format '{{.Names}}' | grep "throbert_host-2"   | head -1)

echo "Containers detectes :"
echo "  Routeur 1 : ${R1:-INTROUVABLE}"
echo "  Routeur 2 : ${R2:-INTROUVABLE}"
echo "  Host 1    : ${H1:-INTROUVABLE}"
echo "  Host 2    : ${H2:-INTROUVABLE}"
echo ""

if [ -z "$R1" ] || [ -z "$R2" ]; then
    echo "Erreur: routeurs introuvables. Verifie que GNS3 est lance."
    exit 1
fi

[ "$MODE" = "multi" ] && SUFFIX="_g" || SUFFIX="_s"


# ft deploy exec le script avec les ac av donne en dessous (cp + exec)
# -z vrai si str vide
deploy() {
    CONTAINER=$1
    SCRIPT=$2
    [ -z "$CONTAINER" ] && echo "  [SKIP] container introuvable pour $SCRIPT" && return
    echo "  -> $CONTAINER : $SCRIPT"
    docker cp "$SCRIPT" "$CONTAINER:/tmp/$SCRIPT"
    docker exec "$CONTAINER" sh "/tmp/$SCRIPT"
}

deploy "$R1" "throbert-1${SUFFIX}-routeur.sh"
deploy "$R2" "throbert-2${SUFFIX}-routeur.sh"
deploy "$H1" "throbert-1_host.sh"
deploy "$H2" "throbert-2_host.sh"

echo ""
echo "Done. Mode '$MODE' applique."

