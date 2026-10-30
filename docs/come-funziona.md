# Come funziona

## Perché Docker e non XAMPP?

XAMPP su Linux include **MariaDB**, non MySQL. Sono molto simili ma non identici: alcune funzioni, messaggi di errore e comportamenti cambiano, e a scuola si usa MySQL 8. Con Docker usiamo l'**immagine ufficiale `mysql:8.0`**, identica a quella dei laboratori, senza installare nulla nel sistema a parte Docker.

## Cosa crea `install.sh`

```
            il tuo PC (solo 127.0.0.1)
 ┌────────────────────────────────────────────────┐
 │  :3306 ──► mysql-scuola  (mysql:8.0)            │
 │              ├─ volume mysql-scuola-data  ◄── i tuoi database
 │              └─ ~/Documents/mysql → /work ◄── i file del tee
 │                    ▲                            │
 │                    │ rete docker "scuola"       │
 │  :80   ──►  pma-scuola (phpmyadmin)             │
 │  :8080 ──►      "                               │
 └────────────────────────────────────────────────┘
```

| Cosa | Nome | A cosa serve |
|---|---|---|
| Container | `mysql-scuola` | Il server MySQL 8 |
| Container | `pma-scuola` | phpMyAdmin |
| Volume | `mysql-scuola-data` | Dove vivono i database. Sopravvive anche se cancelli il container |
| Rete | `scuola` | Fa parlare phpMyAdmin con MySQL |
| Cartella | `~/Documents/mysql` | Montata dentro MySQL come `/work`: qui finiscono i `tee` e da qui legge `source` |
| Comandi | `~/.local/bin/*` | `avvia-mysql`, `stop-mysql`, … |
| Config | `~/.local/share/mysql-scuola/` | La regola Apache che fa funzionare `/phpmyadmin` |

## Dettagli

- **Porte solo su `127.0.0.1`**: root senza password va bene sul tuo PC, ma non deve essere raggiungibile da altri sulla stessa rete.
- **`--restart unless-stopped`**: MySQL ripartirà da solo dopo un riavvio, a meno che tu non l'abbia spento con `stop-mysql`.
- **`avvia-mysql` usa il client dentro il container** (`docker exec`), quindi non serve installare il client MySQL e non ci sono problemi di compatibilità con `caching_sha2_password`.
- **Il client gira con il tuo UID**, così i file creati dal `tee` sono tuoi e non di root.
- **`/phpmyadmin`**: l'immagine ufficiale serve phpMyAdmin su `/`. Il file [`config/phpmyadmin-alias.conf`](../config/phpmyadmin-alias.conf) aggiunge un `Alias` Apache per avere lo stesso indirizzo di XAMPP.

## Comandi Docker utili

```bash
docker ps -a                       # tutti i container
docker logs -f mysql-scuola        # log in tempo reale (Ctrl+C per uscire)
docker exec -it mysql-scuola bash  # una shell dentro il container
docker volume ls                   # i volumi (i dati)
docker system df                   # quanto spazio usa Docker
```
