#!/usr/bin/env bash
# Rimuove container e comandi rapidi.
#
#   ./uninstall.sh           toglie container e comandi, MA tiene i database
#   ./uninstall.sh --tutto   cancella anche i database (irreversibile!)
#
# Docker e i file in ~/Documents/mysql non vengono toccati.
set -e

DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

$DOCKER rm -f mysql-scuola pma-scuola 2>/dev/null || true
$DOCKER network rm scuola 2>/dev/null || true

for c in avvia-mysql stop-mysql avvia-xampp stop-xampp stato-mysql; do
    rm -f "$HOME/.local/bin/$c"
done
rm -rf "$HOME/.local/share/mysql-scuola"

if [ "$1" = "--tutto" ]; then
    read -rp "Cancello DEFINITIVAMENTE tutti i database? Scrivi 'si' per confermare: " ok
    if [ "$ok" = "si" ]; then
        $DOCKER volume rm mysql-scuola-data
        echo "Database cancellati."
    fi
else
    echo "I database sono ancora nel volume 'mysql-scuola-data' (rilancia ./install.sh per riaverli)."
fi
echo "Disinstallazione completata."
