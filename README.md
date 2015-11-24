# CS:GO Multi-Mode Server Manager

Launch and setup your Counter-Strike : Global Offensive Dedicated Server.

## About this fork

This fork shall remove problems of the original csgo-server-launcher (it seemed primarily designed for remote-hosted servers) and allow multiple configurations and set up sourcemod plugins - for using the script in LAN events. 

At some point in the future, it is planned to make a docker container for easier deployment out of this.

### Planned additions

* **MULTIPLE CONFIGURATIONS** for different modes (like competitive/deathmatch/surfing) that can be chosen when starting the server
    * e.g using **csgo-server** start competitive
    * More options shall be controlled using environment variables, like **MAPS** (a mapcycle generator), **TEAM_T**, **TEAM_CT** (automatic team assignment, depends on plugins)
* sourcemod plugin management (including downloading them), and enabling/disabling them based on configuration
* support for Gameserver auth tokens and various other improvements

## Requirements

Of course a Steam account is required to create a Counter-Strike : Global Offensive dedicated server.

Get Gameserver auth tokens for CS:GO (App-ID 730) [here](http://steamcommunity.com/dev/managegameservers)

Required commands :

* [awk](http://en.wikipedia.org/wiki/Awk) is required.
* [screen](http://linux.die.net/man/1/screen) is required.
* [wget](http://en.wikipedia.org/wiki/Wget) is required.
* [tar](http://linuxcommand.org/man_pages/tar1.html) is required.

## Installation - TO BE DONE

## Environment Variables - TO BE REWORKED

* **SCREEN_NAME** - The screen name, you can put what you want but it must be unique and must contain only alphanumeric character.
* **USER** - Name of the user who started the server.
* **IP** - Your WAN IP address.
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
