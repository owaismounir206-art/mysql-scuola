#!/usr/bin/env bash
# Installazione con un solo comando:
#   curl -fsSL https://raw.githubusercontent.com/owaismounir206-art/mysql-scuola/main/get.sh | bash
#
# Tutto dentro main(): bash legge questo script dalla pipe un pezzo alla volta,
# così viene eseguito solo se è arrivato intero.
main() {
    set -euo pipefail
    local ref="${MYSQL_SCUOLA_REF:-main}"
    command -v tar >/dev/null || { echo "Serve il programma tar: installalo e riprova." >&2; exit 1; }

    # Non local: la trap gira quando main() è già finita
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    echo ">> Scarico mysql-scuola"
    curl -fsSL "https://github.com/owaismounir206-art/mysql-scuola/archive/$ref.tar.gz" | tar -xz -C "$tmp" --strip-components=1

    # stdin da /dev/null: i comandi dell'installazione non devono leggere dalla pipe
    bash "$tmp/install.sh" "$@" </dev/null
}

main "$@"
