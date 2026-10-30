# mysql-scuola 🐬

[![test](../../actions/workflows/test.yml/badge.svg)](../../actions/workflows/test.yml)

**MySQL 8 + phpMyAdmin su qualsiasi distro Linux, con un solo comando.**

Pensato per la scuola: hai lo stesso MySQL 8 dei prof, `tee` per salvare il lavoro in `.txt` e phpMyAdmin su `http://localhost/phpmyadmin`, come con XAMPP. Senza impazzire con il MariaDB di XAMPP.

Funziona con **Docker** sotto al cofano, ma non devi sapere niente di Docker.

## 🐧 Distro supportate

| Distro | Docker installato con |
|---|---|
| Arch, CachyOS, Manjaro, EndeavourOS, Garuda | `pacman -S docker` |
| Ubuntu, Debian, Linux Mint, Pop!_OS, Zorin, elementary | `apt install docker.io` |
| Fedora | `dnf install moby-engine` |
| openSUSE Tumbleweed / Leap | `zypper install docker` |
| Void | `xbps-install docker` |
| Alpine | `apk add docker` |
| Gentoo | `emerge app-containers/docker` |

Se hai già Docker installato (anche su un'altra distro), lo script lo usa e basta.
Su RHEL/Rocky/Alma installa prima Docker [dal sito ufficiale](https://docs.docker.com/engine/install/).

---

## 🚀 Installazione (una volta sola)

```bash
git clone https://github.com/owaismounir206-art/mysql-scuola.git
cd mysql-scuola
./install.sh
```

Ti chiede la password (per `sudo`). La prima volta scarica circa 700 MB: dagli qualche minuto.

> ⚠️ **Alla fine fai logout e login (o riavvia il PC).**
> Altrimenti i comandi danno `permission denied`.

## ✅ Uso quotidiano

| Comando | Cosa fa |
|---|---|
| `avvia-mysql` | Accende tutto ed entra nel prompt `mysql>` |
| `avvia-mysql < file.sql` | Esegue un file `.sql` ed esce |
| `stop-mysql` | Spegne tutto (i dati restano) |
| `backup-mysql [database]` | Salva i database in un `.sql` |
| `stato-mysql` | Mostra cosa è acceso e chi occupa le porte |
| `avvia-xampp` / `stop-xampp` | Passa a XAMPP (se lo usi anche) |

**phpMyAdmin:** http://localhost/phpmyadmin → utente `root`, password **vuota**.

### Salvare il lavoro su file (tee)

```sql
mysql> tee esercizio1.txt
mysql> SELECT * FROM studenti;
mysql> notee
mysql> exit
```

Il file finisce in **`~/Documents/mysql/esercizio1.txt`**. Scrivi solo il nome, senza percorso.

## 📚 Documentazione

- [Guida completa all'uso](docs/guida-uso.md): tee, importare `.sql`, backup, phpMyAdmin, DBeaver/VS Code, XAMPP
- [Problemi comuni e soluzioni](docs/problemi-comuni.md): **leggi qui se qualcosa non va**
- [Come funziona](docs/come-funziona.md): per i curiosi
- [Disinstallare](docs/disinstallare.md)

## 🗑️ Disinstallare

```bash
./uninstall.sh          # toglie tutto ma tiene i tuoi database
./uninstall.sh --tutto  # cancella anche i database
```

---

> 🔒 Root non ha password, ma MySQL e phpMyAdmin sono raggiungibili **solo dal tuo PC** (127.0.0.1): nessuno sul Wi‑Fi della scuola può entrarci.
