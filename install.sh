#!/usr/bin/env bash
# Installazione una-tantum di MySQL 8 + phpMyAdmin con Docker (Arch / CachyOS / Manjaro / EndeavourOS)
#
#   ./install.sh            installa tutto (sicuro da rilanciare)
#   ./install.sh --ricrea   ricrea i container (i database NON vengono persi)
set -e
cd "$(dirname "$0")"

RICREA=0
[ "$1" = "--ricrea" ] && RICREA=1

BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/mysql-scuola"
WORK="$HOME/Documents/mysql"

verde() { printf '\033[1;32m>> %s\033[0m\n' "$*"; }
giallo() { printf '\033[1;33m!! %s\033[0m\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
    echo "Non lanciare lo script con sudo: lancialo come utente normale (./install.sh)." >&2
    exit 1
fi

# 1. Docker -------------------------------------------------------------------
if ! command -v docker >/dev/null; then
    if command -v pacman >/dev/null; then
        verde "Installo Docker (ti verrà chiesta la password)"
        sudo pacman -S --needed --noconfirm docker
    else
        echo "Questo script installa Docker solo su distro Arch-based." >&2
        echo "Installa Docker a mano (https://docs.docker.com/engine/install/) e rilancialo." >&2
        exit 1
    fi
fi
verde "Avvio il servizio Docker"
sudo systemctl enable --now docker.service

if ! id -nG "$USER" | grep -qw docker; then
    verde "Aggiungo $USER al gruppo docker"
    sudo usermod -aG docker "$USER"
    DEVE_RIENTRARE=1
fi

# Finché non rientri nella sessione il gruppo non è attivo: usiamo sudo per ora
DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

# 2. Libera le porte se c'è XAMPP acceso ------------------------------------------
if [ -x /opt/lampp/lampp ]; then
    verde "Spengo XAMPP (usa le stesse porte 80 e 3306)"
    sudo /opt/lampp/lampp stop >/dev/null 2>&1 || true
fi

# 3. File di supporto ---------------------------------------------------------
mkdir -p "$BIN" "$SHARE" "$WORK"
install -m 644 config/phpmyadmin-alias.conf "$SHARE/phpmyadmin-alias.conf"

# 4. Container ----------------------------------------------------------------
$DOCKER network inspect scuola >/dev/null 2>&1 || $DOCKER network create scuola >/dev/null

if [ "$RICREA" = 1 ]; then
    verde "Elimino i vecchi container (i dati restano nel volume)"
    $DOCKER rm -f mysql-scuola pma-scuola >/dev/null 2>&1 || true
fi

if ! $DOCKER container inspect mysql-scuola >/dev/null 2>&1; then
    verde "Creo il container MySQL 8 (il primo download richiede qualche minuto)"
    # - porta solo su 127.0.0.1: root senza password NON è raggiungibile dalla rete
    # - volume mysql-scuola-data: i database sopravvivono anche se ricrei il container
    # - ~/Documents/mysql montata su /work: lì finiscono i file del tee
    $DOCKER run -d --name mysql-scuola --network scuola \
        -p 127.0.0.1:3306:3306 \
        -e MYSQL_ALLOW_EMPTY_PASSWORD=yes \
        -v mysql-scuola-data:/var/lib/mysql \
        -v "$WORK:/work" \
        --restart unless-stopped \
        mysql:8.0 >/dev/null
else
    giallo "mysql-scuola esiste già, lo lascio com'è"
fi

if ! $DOCKER container inspect pma-scuola >/dev/null 2>&1; then
    verde "Creo il container phpMyAdmin"
    # http://localhost/phpmyadmin (come XAMPP) e anche http://localhost:8080
    $DOCKER run -d --name pma-scuola --network scuola \
        -p 127.0.0.1:80:80 -p 127.0.0.1:8080:80 \
        -e PMA_HOST=mysql-scuola \
        -v "$SHARE/phpmyadmin-alias.conf:/etc/apache2/conf-enabled/phpmyadmin-alias.conf:ro" \
        --restart unless-stopped \
        phpmyadmin >/dev/null
else
    giallo "pma-scuola esiste già, lo lascio com'è"
fi

# 5. Comandi rapidi -----------------------------------------------------------
verde "Installo i comandi in $BIN"
for f in bin/*; do
    install -m 755 "$f" "$BIN/"
done

case ":$PATH:" in
    *":$BIN:"*) ;;
    *)
        giallo "$BIN non era nel PATH: lo aggiungo"
        grep -qs 'local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        command -v fish >/dev/null && fish -c "fish_add_path -U $BIN" || true
        ;;
esac

echo
$DOCKER ps --filter name=scuola --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo
verde "FATTO!"
echo "   Entrare in MySQL:   avvia-mysql"
echo "   phpMyAdmin:         http://localhost/phpmyadmin   (utente root, password vuota)"
echo "   Spegnere tutto:     stop-mysql"
if [ "${DEVE_RIENTRARE:-0}" = 1 ]; then
    echo
    giallo "IMPORTANTE: fai logout e login (o riavvia il PC) prima di usare i comandi,"
    giallo "altrimenti Docker darà 'permission denied'."
fi
