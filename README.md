# mysql-arch 🐬

**MySQL 8 + phpMyAdmin on Arch Linux / CachyOS, set up with a single command.**

Made for school: it gives you the same MySQL 8 the teachers use, `tee` to save your work to `.txt` files, and phpMyAdmin at `http://localhost/phpmyadmin`, just like XAMPP. You don't have to fight with the MariaDB that XAMPP bundles.

Under the hood it uses **Docker**, but you don't need to know anything about it.

---

## 🚀 Installation (one time only)

Open the terminal and paste:

```bash
git clone https://github.com/owaismounir206-art/mysql-arch.git
cd mysql-arch
./install.sh
```

It will ask for your password (for `sudo`). The first time it downloads about 700 MB, so give it a few minutes.

> ⚠️ **When it finishes, log out and back in (or restart your PC).**
> Otherwise every command will fail with `permission denied`.

## ✅ Daily use

| Command | What it does |
|---|---|
| `avvia-mysql` | Starts everything and drops you at the `mysql>` prompt |
| `stop-mysql` | Shuts everything down (your data stays) |
| `stato-mysql` | Shows what is running |
| `avvia-xampp` / `stop-xampp` | Switches to XAMPP, if you also use it |

**phpMyAdmin:** http://localhost/phpmyadmin, user `root`, password **empty**.

### Saving your work to a file (tee)

```sql
mysql> tee esercizio1.txt
mysql> SELECT * FROM studenti;
mysql> notee
mysql> exit
```

The file ends up in **`~/Documents/mysql/esercizio1.txt`**. Write only the name, without a path.

## 📚 Documentation

- [Complete usage guide](docs/guida-uso.md): tee, importing `.sql` files, phpMyAdmin, XAMPP
- [Common problems and fixes](docs/problemi-comuni.md): **start here if something doesn't work**
- [How it works](docs/come-funziona.md): for the curious
- [Uninstalling](docs/disinstallare.md)

## 🗑️ Uninstalling

```bash
./uninstall.sh          # removes everything but keeps your databases
./uninstall.sh --tutto  # also deletes your databases
```

---

> 🔒 Root has no password, but MySQL and phpMyAdmin are reachable **only from your own PC** (127.0.0.1). Nobody on the school Wi‑Fi can get in.
