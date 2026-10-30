# Problemi comuni e soluzioni

Prima di tutto lancia `stato-mysql`: ti dice cosa è acceso e chi sta usando le porte.

---

## `permission denied while trying to connect to the Docker daemon socket`

Non hai ancora i permessi per Docker. Succede quasi sempre perché **dopo l'installazione non hai fatto logout/login**.

1. Fai logout e rientra (o riavvia il PC).
2. Controlla con `groups`: nella lista deve comparire `docker`.
3. Se `docker` non c'è:
   ```bash
   sudo usermod -aG docker $USER
   ```
   e poi di nuovo logout/login.

Soluzione temporanea solo per il terminale aperto: `newgrp docker`.

## `Cannot connect to the Docker daemon` / `Docker è spento`

Il servizio Docker non è attivo:

```bash
sudo systemctl enable --now docker      # quasi tutte le distro
sudo rc-service docker start            # Alpine, Gentoo (OpenRC), Artix
sudo ln -s /etc/sv/docker /var/service/ # Void
```

## `fish: Unknown command: avvia-mysql` (o `command not found` in bash)

La cartella `~/.local/bin` non è nel PATH.

- **fish:** `fish_add_path ~/.local/bin`
- **bash:** `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc` e riapri il terminale

Poi controlla che i comandi esistano: `ls ~/.local/bin/avvia-mysql`. Se non c'è, rilancia `./install.sh`.

## `avvia-mysql` non stampa niente e resta bloccato

Succedeva con le versioni vecchie se avevi usato XAMPP: il suo `lampp status` trova dei file `.pid` rimasti e chiede di nascosto conferma per cancellarli. Aggiorna il repo e reinstalla i comandi:

```bash
git pull && ./install.sh
```

Per pulire i file rimasti di XAMPP (facoltativo):

```bash
sudo rm -f /opt/lampp/logs/httpd.pid /opt/lampp/var/proftpd.pid /opt/lampp/var/mysql/*.pid
```

## `Il container mysql-scuola non esiste`

L'installazione non è andata a buon fine o hai disinstallato. Rilancia:

```bash
./install.sh
```

## phpMyAdmin non si apre

*"Connessione non riuscita"* su `localhost/phpmyadmin`:

1. Hai dato `avvia-mysql`? phpMyAdmin si accende insieme a MySQL.
2. `stato-mysql`: `pma-scuola` deve essere **Up**.
3. È acceso XAMPP? Occupa la porta 80. Dai `stop-xampp` e poi `avvia-mysql`.
4. Prova http://localhost:8080 (stessa cosa, porta diversa).
5. Se `pma-scuola` è in stato *Exited/Created* con un errore di porta già in uso:
   ```bash
   sudo ss -ltnp | grep -E ':80 |:8080 '
   ```
   ti dice quale programma occupa la porta (spesso un altro Apache/nginx: `sudo systemctl stop httpd nginx`).

## phpMyAdmin funziona solo su `localhost:8080`

All'installazione la porta 80 era occupata (tipico su Ubuntu/Debian se è installato `apache2`, o se hai nginx), quindi phpMyAdmin è stato messo solo sulla 8080. Usa http://localhost:8080, oppure libera la porta 80 e ricrea i container:

```bash
sudo systemctl disable --now apache2   # Ubuntu/Debian
sudo systemctl disable --now httpd     # Arch/Fedora
./install.sh --ricrea
```

## phpMyAdmin: *"Login senza password vietato"* / *"Accesso negato"*

Stai usando il phpMyAdmin di **XAMPP** e non quello di Docker (succede se XAMPP è acceso). Dai `avvia-mysql`, che spegne XAMPP, e ricarica la pagina.

## `Bind for 127.0.0.1:3306 failed: port is already allocated` / `address already in use`

Un altro MySQL/MariaDB sta già usando la porta 3306. Di solito è uno di questi:

```bash
sudo /opt/lampp/lampp stop        # XAMPP
sudo systemctl stop mariadb mysql mysqld  # MariaDB/MySQL installati dalla distro
```

Se vuoi che MariaDB di sistema non parta più all'avvio: `sudo systemctl disable mariadb`.

Poi `avvia-mysql`.

## `ERROR 2002 / 2003: Can't connect to MySQL server`

MySQL non ha finito di avviarsi. Il primo avvio in assoluto può richiedere **30-60 secondi**. Aspetta e riprova. Se persiste, guarda i log:

```bash
docker logs --tail 30 mysql-scuola
```

## Il file del `tee` non c'è

- Hai cancellato e ricreato `~/Documents/mysql`? Docker la ricrea come **root** e il tee non può più scriverci. `avvia-mysql` lo sistema da solo all'avvio; se vedi ancora `Permesso negato`, dai `stop-mysql` e poi `avvia-mysql`.

- Hai dato `notee` (o `exit`) alla fine? Fino ad allora il file potrebbe essere incompleto.
- Hai scritto un percorso (`tee ~/file.txt`)? Scrivi **solo il nome**: `tee file.txt`.
- Cerca in **`~/Documents/mysql/`**, non nella cartella dove hai aperto il terminale.
- Il sistema è in italiano e hai la cartella `Documenti` invece di `Documents`? Il file è comunque in `~/Documents/mysql` (la crea lo script).

## `ERROR 1045: Access denied for user 'root'`

Qualcuno ha messo una password a root. Entra con la password che hai impostato:

```bash
avvia-mysql -p
```

Per tornare a root senza password (dentro MySQL):

```sql
ALTER USER 'root'@'%' IDENTIFIED BY '';
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
```

## Fedora: `Permission denied` sui file del tee

È SELinux. `install.sh` lo gestisce da solo, ma se hai creato i container prima di aggiornare lo script rilancia:

```bash
./install.sh --ricrea
```

## Ubuntu: Docker installato con snap dà errori di permessi

Se avevi installato Docker con `snap`, a volte non vede le cartelle fuori dalla home e dà problemi di permessi. Meglio la versione apt:

```bash
sudo snap remove docker
./install.sh
```

## Il primo `install.sh` è lentissimo / si blocca su `Pulling`

Sta scaricando le immagini (~700 MB). Con il Wi‑Fi della scuola può volerci molto: meglio farlo a casa. Se si è interrotto, rilancia `./install.sh`: riprende da dove era rimasto.

## Voglio ripartire da zero

Mantenendo i database:

```bash
./install.sh --ricrea
```

Cancellando **tutto**, database compresi:

```bash
./uninstall.sh --tutto
./install.sh
```

---

Problema non in lista? Apri una [issue](../../issues) incollando l'output di:

```bash
stato-mysql; docker logs --tail 30 mysql-scuola; docker logs --tail 30 pma-scuola
```
