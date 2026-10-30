#!/usr/bin/env bash
# Installazione una-tantum di MySQL 8 + phpMyAdmin con Docker, su qualsiasi distro Linux.
#
#   ./install.sh            installa tutto (sicuro da rilanciare)
#   ./install.sh --ricrea   ricrea i container (i database NON vengono persi)
set -euo pipefail
cd "$(dirname "$0")"

RICREA=0
[ "${1:-}" = "--ricrea" ] && RICREA=1

BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/mysql-scuola"
WORK="$HOME/Documents/mysql"

verde()  { printf '\033[1;32m>> %s\033[0m\n' "$*"; }
giallo() { printf '\033[1;33m!! %s\033[0m\n' "$*"; }
rosso()  { printf '\033[1;31mXX %s\033[0m\n' "$*" >&2; }

if [ "$(id -u)" -eq 0 ]; then
    rosso "Non lanciare lo script con sudo: lancialo come utente normale (./install.sh)."
    exit 1
fi

porta_occupata() { ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]$1\$"; }

# 1. Installa Docker ----------------------------------------------------------------
installa_docker() {
    . /etc/os-release 2>/dev/null || true
    verde "Installo Docker per ${PRETTY_NAME:-la tua distro} (ti verrà chiesta la password)"
    if   command -v pacman      >/dev/null; then sudo pacman -S --needed --noconfirm docker
    elif command -v apt-get     >/dev/null; then sudo apt-get update && sudo apt-get install -y docker.io
    elif command -v dnf         >/dev/null; then
        # Fedora ha "moby-engine" nei repo; RHEL/Rocky/Alma no
        sudo dnf install -y moby-engine || {
            rosso "Su RHEL/Rocky/Alma Docker non è nei repo ufficiali."
            rosso "Segui https://docs.docker.com/engine/install/ e rilancia ./install.sh"; exit 1; }
    elif command -v zypper      >/dev/null; then sudo zypper -n install docker
    elif command -v xbps-install>/dev/null; then sudo xbps-install -Sy docker
    elif command -v apk         >/dev/null; then sudo apk add docker
    elif command -v emerge      >/dev/null; then sudo emerge --noreplace app-containers/docker app-containers/docker-cli
    else
        rosso "Distro non riconosciuta. Installa Docker a mano: https://docs.docker.com/engine/install/"
        rosso "poi rilancia ./install.sh"
        exit 1
    fi
}

avvia_servizio_docker() {
    verde "Avvio il servizio Docker (e lo abilito all'avvio del PC)"
    if command -v systemctl >/dev/null && [ -d /run/systemd/system ]; then
        sudo systemctl enable --now docker.service
    elif command -v rc-service >/dev/null; then          # Alpine, Gentoo OpenRC, Artix
        sudo rc-update add docker default
        sudo rc-service docker start || true
    elif [ -d /etc/sv/docker ]; then                     # Void (runit)
        sudo ln -sf /etc/sv/docker /var/service/
        sleep 3
    else
        giallo "Non so avviare Docker sul tuo init system: avvialo a mano e rilancia lo script."
    fi
}

if ! command -v docker >/dev/null; then
    installa_docker
fi
if ! docker info >/dev/null 2>&1 && ! sudo docker info >/dev/null 2>&1; then
    avvia_servizio_docker
fi

if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi
DEVE_RIENTRARE=0
if ! id -nG "$USER" | grep -qw docker; then
    verde "Aggiungo $USER al gruppo docker"
    sudo usermod -aG docker "$USER"
    DEVE_RIENTRARE=1
fi

# Finché non rientri nella sessione il gruppo non è attivo: per ora usiamo sudo
DOCKER="docker"
docker info >/dev/null 2>&1 || DOCKER="sudo docker"
if ! $DOCKER info >/dev/null 2>&1; then
    rosso "Docker non risponde. Prova: sudo systemctl status docker"
    exit 1
fi

# 2. Libera le porte --------------------------------------------------------------
if pgrep -f '^/opt/lampp/s?bin/(httpd|mysqld|mariadbd)' >/dev/null; then
    verde "Spengo XAMPP (usa le stesse porte 80 e 3306)"
    sudo /opt/lampp/lampp stop >/dev/null 2>&1 || true
fi

container_esiste() { $DOCKER container inspect "$1" >/dev/null 2>&1; }

if [ "$RICREA" = 1 ]; then
    verde "Elimino i vecchi container (i dati restano nel volume)"
    $DOCKER rm -f mysql-scuola pma-scuola >/dev/null 2>&1 || true
fi

if ! container_esiste mysql-scuola && porta_occupata 3306; then
    rosso "La porta 3306 è già occupata da un altro MySQL/MariaDB:"
    sudo ss -ltnp 2>/dev/null | grep -E '[:.]3306\b' >&2 || true
    rosso "Spegnilo (es. sudo systemctl disable --now mariadb mysql mysqld) e rilancia ./install.sh"
    exit 1
fi

# 3. File di supporto ---------------------------------------------------------------
mkdir -p "$BIN" "$SHARE" "$WORK"
install -m 644 config/phpmyadmin-alias.conf "$SHARE/phpmyadmin-alias.conf"

# Fedora/RHEL con SELinux: i bind mount vanno etichettati, altrimenti "permission denied"
Z=""
if command -v selinuxenabled >/dev/null && selinuxenabled; then Z="z"; fi

# 4. Container ----------------------------------------------------------------------
$DOCKER network inspect scuola >/dev/null 2>&1 || $DOCKER network create scuola >/dev/null

if ! container_esiste mysql-scuola; then
    verde "Creo il container MySQL 8 (il primo download richiede qualche minuto)"
    # - porta solo su 127.0.0.1: root senza password NON è raggiungibile dalla rete
    # - volume mysql-scuola-data: i database sopravvivono anche se ricrei il container
    # - ~/Documents/mysql montata su /work: lì finiscono i file del tee
    $DOCKER run -d --name mysql-scuola --network scuola \
        -p 127.0.0.1:3306:3306 \
        -e MYSQL_ALLOW_EMPTY_PASSWORD=yes \
        -v mysql-scuola-data:/var/lib/mysql \
        -v "$WORK:/work${Z:+:$Z}" \
        --restart unless-stopped \
        mysql:8.0 >/dev/null
else
    giallo "mysql-scuola esiste già, lo lascio com'è"
fi

if ! container_esiste pma-scuola; then
    PORTE=(-p 127.0.0.1:8080:80)
    if porta_occupata 80; then
        giallo "La porta 80 è occupata (Apache/nginx di sistema?): phpMyAdmin sarà solo su http://localhost:8080"
    else
        PORTE+=(-p 127.0.0.1:80:80)
    fi
    verde "Creo il container phpMyAdmin"
    $DOCKER run -d --name pma-scuola --network scuola \
        "${PORTE[@]}" \
        -e PMA_HOST=mysql-scuola \
        -v "$SHARE/phpmyadmin-alias.conf:/etc/apache2/conf-enabled/phpmyadmin-alias.conf:ro${Z:+,$Z}" \
        --restart unless-stopped \
        phpmyadmin:5 >/dev/null
else
    giallo "pma-scuola esiste già, lo lascio com'è"
fi

# 5. Comandi rapidi -----------------------------------------------------------------
verde "Installo i comandi in $BIN"
for f in bin/*; do
    install -m 755 "$f" "$BIN/"
done

case ":$PATH:" in
    *":$BIN:"*) ;;
    *)
        giallo "$BIN non era nel PATH: lo aggiungo (riapri il terminale)"
        for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
            [ -f "$rc" ] && ! grep -qs '.local/bin' "$rc" && echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        done
        if command -v fish >/dev/null; then fish -c "fish_add_path -U $BIN" || true; fi
        ;;
esac

# 6. Verifica finale ----------------------------------------------------------------
printf '\033[1;32m>> Attendo che MySQL sia pronto\033[0m'
for _ in $(seq 1 90); do
    $DOCKER exec mysql-scuola mysqladmin ping -h 127.0.0.1 -u root --silent >/dev/null 2>&1 && break
    printf "."; sleep 2
done
echo

echo
$DOCKER ps --filter name=scuola --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo
verde "FATTO!"
echo "   Entrare in MySQL:   avvia-mysql"
if $DOCKER port pma-scuola 2>/dev/null | grep -q ':80$'; then
    echo "   phpMyAdmin:         http://localhost/phpmyadmin   (utente root, password vuota)"
else
    echo "   phpMyAdmin:         http://localhost:8080   (utente root, password vuota)"
fi
echo "   Spegnere tutto:     stop-mysql"
if [ "$DEVE_RIENTRARE" = 1 ]; then
    echo
    giallo "IMPORTANTE: fai logout e login (o riavvia il PC) prima di usare i comandi,"
    giallo "altrimenti Docker darà 'permission denied'."
fi
