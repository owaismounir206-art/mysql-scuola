# Guida all'uso

## Entrare e uscire da MySQL

```bash
avvia-mysql
```

Accende MySQL e phpMyAdmin (se erano spenti), aspetta che siano pronti e ti porta al prompt:

```
mysql>
```

Per uscire: `exit` (oppure `Ctrl+D`). **Uscire NON spegne MySQL**: resta acceso in sottofondo finché non dai `stop-mysql` o spegni il PC.

> Dopo un riavvio MySQL si riaccende da solo, **a meno che** prima di spegnere non avessi dato `stop-mysql`.

## Salvare il lavoro con `tee`

`tee` registra in un file tutto quello che scrivi e tutto quello che MySQL risponde.

```sql
tee cognome_esercizio.txt
-- ...tutte le tue query...
notee
```

- Scrivi **solo il nome del file**, niente percorso (`tee /home/...` NON funziona).
- Il file finisce in **`~/Documents/mysql/`** (in Dolphin/Nautilus: *Documenti → mysql*).
- Se rilanci `tee` con lo stesso nome, il testo viene **aggiunto in fondo**, non sovrascritto.

## Importare un file `.sql`

1. Copia il file in `~/Documents/mysql/` (es. `scuola.sql`).
2. Dentro MySQL:

```sql
source scuola.sql
```

In alternativa da phpMyAdmin: **Importa → Scegli file → Esegui**.

## Esportare un database

Da terminale (fuori da MySQL):

```bash
docker exec mysql-scuola mysqldump -u root nome_database > ~/Documents/mysql/backup.sql
```

Oppure da phpMyAdmin: seleziona il database → **Esporta**.

## phpMyAdmin

Apri **http://localhost/phpmyadmin** (funziona anche http://localhost:8080).

- Utente: `root`
- Password: *(lascia vuoto)*

Se la pagina non si apre: hai dato `avvia-mysql`? Vedi anche [problemi comuni](problemi-comuni.md#phpmyadmin-non-si-apre).

## Collegarsi da altri programmi (DBeaver, VS Code, Python, PHP…)

| Campo | Valore |
|---|---|
| Host | `127.0.0.1` (meglio di `localhost`, vedi sotto) |
| Porta | `3306` |
| Utente | `root` |
| Password | *(vuota)* |

> Usa `127.0.0.1` e non `localhost`: alcuni client con `localhost` cercano un socket locale invece della porta di rete e non trovano il server.

## Usare anche XAMPP

XAMPP e questo setup usano le **stesse porte** (80 e 3306), quindi non possono essere accesi insieme. I comandi pensano a tutto:

- `avvia-xampp` → spegne Docker e accende XAMPP
- `avvia-mysql` → spegne XAMPP (se acceso) e accende Docker

I database di XAMPP e quelli di Docker sono **separati**: quello che crei in uno non lo vedi nell'altro.

## Vedere cosa è acceso

```bash
stato-mysql
```
