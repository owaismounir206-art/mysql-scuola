#!/usr/bin/env bash
# Test completo: presuppone che ./install.sh sia già stato lanciato.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m  ✗ %s\033[0m\n' "$*"; exit 1; }

WORK=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/work"}}{{.Source}}{{end}}{{end}}' mysql-scuola)

v=$(echo "SELECT VERSION();" | avvia-mysql -N 2>/dev/null)
[[ $v == 8.0.* ]] && ok "MySQL $v" || fail "versione inattesa: $v"

# In un vero terminale (pty), con timeout: intercetta comandi che si bloccano
# in attesa di input invisibili (es. il vecchio "lampp status")
out=$(timeout 60 script -qec "avvia-mysql -N -e 'SELECT 40+2'" /dev/null 2>&1 | tr -d '\r') || true
[[ $out == *42* ]] && ok "avvia-mysql funziona in un terminale interattivo" || fail "avvia-mysql bloccato o fallito nel terminale: $out"

rm -f "$WORK/test-e2e.txt"
printf "tee test-e2e.txt\nSELECT 'ciao' AS saluto;\nnotee\n" | avvia-mysql >/dev/null 2>&1
grep -q ciao "$WORK/test-e2e.txt" && ok "tee scrive in $WORK" || fail "file del tee mancante"
[ -O "$WORK/test-e2e.txt" ] && ok "il file del tee appartiene a $USER" || fail "il file del tee non è tuo"
rm -f "$WORK/test-e2e.txt"

printf "CREATE DATABASE IF NOT EXISTS e2e; USE e2e; CREATE TABLE IF NOT EXISTS t(x INT); INSERT INTO t VALUES (42);\n" | avvia-mysql 2>/dev/null
out=$(backup-mysql e2e)
f=$(ls -t "$WORK"/backup-e2e-*.sql | head -1)
grep -q "42" "$f" && ok "backup-mysql: $out" || fail "backup senza dati"
echo "DROP DATABASE e2e;" | avvia-mysql 2>/dev/null
avvia-mysql < "$f" 2>/dev/null
[ "$(echo 'SELECT x FROM e2e.t;' | avvia-mysql -N 2>/dev/null)" = 42 ] && ok "ripristino da backup" || fail "ripristino fallito"
echo "DROP DATABASE e2e;" | avvia-mysql 2>/dev/null; rm -f "$f"

for url in http://localhost:8080/ http://localhost/phpmyadmin/; do
    if docker port pma-scuola | grep -q ':80$' || [[ $url == *8080* ]]; then
        [[ $(curl -fsL "$url") == *"<title>phpMyAdmin"* ]] && ok "phpMyAdmin su $url" || fail "phpMyAdmin non risponde su $url"
    fi
done

docker port mysql-scuola | grep -q '^3306/tcp -> 127.0.0.1:3306$' && ok "MySQL raggiungibile solo da 127.0.0.1" || fail "porta 3306 esposta in rete!"

stop-mysql >/dev/null
[ -z "$(docker ps -q --filter name=scuola)" ] && ok "stop-mysql spegne tutto" || fail "container ancora accesi"
avvia-mysql < /dev/null >/dev/null 2>&1
[ "$(docker ps -q --filter name=scuola | wc -l)" = 2 ] && ok "avvia-mysql riaccende tutto" || fail "container non ripartiti"

printf '\n\033[1;32mTutti i test passati.\033[0m\n'
