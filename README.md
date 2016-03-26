# CS:GO *Multi* Server Manager

Launch and set up **Counter-Strike: Global Offensive** Dedicated Servers.

## About this fork

This fork is a complete rewrite of [csgo-server-launcher]{https://github.com/crazy-max/csgo-server-launcher} (which seemed to be primarily designed for rented root servers). Intention is to make server management easier in both shared server and LAN environments.

Currently licensed as LGPLv3. When all original code and documentation has been replaced by own, this is planned to be relicensed under Apache 2.0.

### Currently working features

* SteamCMD and Game Installation

### Planned features

The emphasis is on **MULTI**
* **_MULTIPLE_ USERS**: An admin-client system for sharing the base installation. This can save bandwidth/storage
* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously. Supporting network bridges would be nice for the future.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server
    * e.g using **csgo-server** start competitive
    * More options should be controlled using environment variables, like **MAPS** (a mapcycle generator), **TEAM_T**, **TEAM_CT** (automatic team assignment, depends on plugins)

* It should, though, still be easy to set it up just for one user
* Sourcemod plugin management for each instance (including downloading them), and enabling/disabling them based on configuration
* Support for Gameserver auth tokens and various other improvements

## Requirements

Of course, a Steam account is required to create a CS:GO dedicated server. Also get Gameserver auth tokens for CS:GO (App-ID 730) [here](http://steamcommunity.com/dev/managegameservers)

Required commands on the server:

* awk  ([https://en.wikipedia.org/wiki/Awk]) (should be default)
* tmux ([https://tmux.github.io/])
* wget ([https://en.wikipedia.org/wiki/Wget])
* tar  ([http://linuxcommand.org/man_pages/tar1.html])

## Installation - TO BE DONE

## Environment Variables - TO BE REWORKED

The main configuration file, by default, will be placed in ~/csgo-msm.conf. It will set up all the important environment variables.

* **ADMIN** - Name of the user that 'controls' the installation
* **

* **USER** - Name of the user who started the server.
* **PORT** - The port that your server should listen on.
<br /><br />
* **DIR_STEAMCMD** - Path to steamcmd.
* **STEAM_LOGIN** - Your steam account username.
* **STEAM_PASSWORD** - Your steam account password.
* **STEAM_RUNSCRIPT** - Name of the script that steamcmd should execute for autoupdate. This file is created on the fly, you don't normally need to change this variable.
<br /><br />
* **DIR_ROOT** - Root directory for the server.
* **DIR_GAME** - Path to the game.
* **DIR_LOGS** - Directory of game's logs.
* **DAEMON_GAME** - You don't normally need to change this variable.
<br /><br />
* **UPDATE_LOG** - The update log file name.
* **UPDATE_EMAIL** - Mail address where the update's logs are sent. Leave empty to disable sending mail.
* **UPDATE_RETRY** - Number of retries in case of failure of the update.
<br /><br />
* **API_AUTHORIZATION_KEY** - To download maps from the workshop, your server needs access to the steam web api. Leave empty if the ``webapi_authkey.txt`` file exists. Otherwise, to allow this you'll need an authorization key which you can generate : http://steamcommunity.com/dev/apikey
* **WORKSHOP_COLLECTION_ID** - A collection id from the Maps Workshop. The API_AUTHORIZATION_KEY is required. More info : https://developer.valvesoftware.com/wiki/CSGO_Workshop_For_Server_Operators
* **WORKSHOP_START_MAP** - A map id in the selected collection (WORKSHOP_COLLECTION_ID). The API_AUTHORIZATION_KEY is required.
<br /><br />
* **MAXPLAYERS** - Maximum players that can connect.
* **TICKRATE** - The tickrate that your server will operate at.
* **EXTRAPARAMS** - Custom command line parameters
<br /><br />
* **PARAM_START** - Launch settings server.
* **PARAM_UPDATE** - Update settings server.

If you change the location of the config file, do not forget to change the path in the csgo-server-launcher script file for the CONFIG_FILE var (default ``/etc/csgo-server-launcher/csgo-server-launcher.conf``).

## Usage

For the console mod, press CTRL+A then D to stop the screen without stopping the server.

* **start** - Start the server with the PARAM_START var in a screen.
* **stop** - Stop the server and close the screen loaded.
* **status** - Display the status of the server (screen down or up)
* **restart** - Restart the server (stop && start)
* **console** - Display the server console where you can enter commands.
* **update** - Update the server based on the PARAM_UPDATE then save the log file in LOG_DIR and send an e-mail to LOG_EMAIL if the var is filled.
* **create** - Create a server (script must be configured first).

Example : ``service csgo-server-launcher start``

## Automatic update with cron

You can automatically update your game server by calling the script in a crontab.
Just add this line in your crontab and change the folder if necessary.

```console
0 4 * * * cd /etc/init.d/csgo-server-launcher update >/dev/null 2>&1
```

This will update your server every day at 4 am.

## License

LGPL. See ``LICENSE`` for more details.

## More infos

http://www.crazyws.fr/tutos/installer-un-serveur-counter-strike-global-offensive-X4LCM.html
