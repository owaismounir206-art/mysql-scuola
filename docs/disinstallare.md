# Disinstallare

```bash
disinstalla-mysql
```

Toglie container, rete e comandi rapidi, **ma tiene i tuoi database** nel volume `mysql-scuola-data`. Se un giorno reinstalli ritrovi tutto com'era.

## Cancellare anche i database

```bash
disinstalla-mysql --tutto
```

Chiede conferma. **Non si torna indietro**: se ti servono, prima fai un backup con `backup-mysql`.

## Togliere anche Docker

Lo script non tocca Docker, perché potresti usarlo per altro. Per rimuoverlo del tutto:

```bash
docker system prune -a --volumes   # cancella TUTTE le immagini/container/volumi Docker
sudo systemctl disable --now docker
sudo pacman -Rns docker            # Arch e derivate
sudo apt purge docker.io           # Ubuntu/Debian/Mint
sudo dnf remove moby-engine        # Fedora
sudo zypper remove docker          # openSUSE
sudo gpasswd -d $USER docker
```

I file `.txt` e i backup in `~/Documents/mysql` non vengono mai cancellati automaticamente.
