# What is it?
Sailx is a shell script that wraps the default laravel sail command and adds extra features:

- Can be run from any subfolder in your Laravel project.
- Can load/unload the xdebug extension without restarting the container.
- Adds convenient shorthand commands (see below)
- Unrecognized commands are sent to the container as bash commands. 

# Shorthand commands
| Command | Description |
| ------- | ----------- |
| `[i/install]` | Runs composer install and npm ci |
| `[r/require] vendor/package` | Install package with composer |
| `[dev/watch/hot/production]` | Runs the npm script in package.json |
| `some:command` | As long as the first argument contains a colon, it will be interpreted as an artisan command. |
| `tail` | Tails all log files in storage/logs |
| `xdebug [on/off/status]` | Completely loads/unloads xdebug very quickly |
| `root [command]` | Run command as root in the container |
| `anything else` | Will run as a bash command in the container

# Installation
Put the script somewhere in your `PATH` or use an alias.