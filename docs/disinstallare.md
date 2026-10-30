# Uninstalling

From the repo folder:

```bash
./uninstall.sh
```

This removes the containers, the network and the quick commands, **but keeps your databases** in the `mysql-scuola-data` volume. If you run `./install.sh` again later, you'll find everything as you left it.

## Deleting the databases too

```bash
./uninstall.sh --tutto
```

It asks for confirmation. **This cannot be undone.** Do a backup first if you need it (see the [usage guide](guida-uso.md#esportare-un-database)).

## Removing Docker as well

The script doesn't touch Docker, because you might be using it for something else. To remove it completely:

```bash
sudo systemctl disable --now docker
docker system prune -a --volumes   # deletes ALL images/containers/volumes (before the removal)
sudo pacman -Rns docker
sudo gpasswd -d $USER docker
```

The `.txt` files in `~/Documents/mysql` are never deleted automatically.
