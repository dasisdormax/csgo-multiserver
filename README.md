# CS:GO *Multi* Server Manager (MSM)

Launch and set up **Counter-Strike: Global Offensive** Dedicated Servers.




## About this project

*csgo-multiserver* is an administration tool for CS:GO that helps you with the setup, configuration and control of your server(s).

Being specifically designed for LAN environments, it allows you to control many servers running on multiple machines simultaneously. In addition, multiple server instances can share the same base files, saving your precious disk space and bandwidth.

*csgo-multiserver* started as a fork of [csgo-server-launcher](https://github.com/crazy-max/csgo-server-launcher) (which seemed to be designed for rented root servers). By now, all features have been rewritten by scratch.

### The current state

This script is quite capable already, with the server setup, updating, and basic server control functions implemented. Next up are remote control features that allow you to control servers running on different machines.

However, this script is nowhere near complete. A lot of work still needs to be done regarding the _configuration_ and _customization_ of servers.

In addition, I haven't had many opportunities for testing yet, so I'd appreciate every bit of feedback.




## Currently working features

* SteamCMD and Game Installation, checking for and performing updates
* CS:GO Server instance creation
* Instance-specific server configuration
* Running a server basically works (Including logging)! Yay! 




## Planned features

The emphasis is on **MULTI**

* **_MULTIPLE_ USERS**: An admin-client system for sharing the base installation. Thus, the same files do not have to be downloaded and stored multiple times.
* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server

Additional plans:

* While the _MULTI_ features are the highlight, managing a single server for yourself should be just as easy.
* Sourcemod plugin management for each instance (including downloading them), and enabling/disabling them based on configuration
* Game configuration upon launch with environment variables. Possible features:
	- Mapcycle generator (as `MAPS` variable)
	- automatic team assignment (as `TEAM_T` and `TEAM_CT` variable)




## Requirements

These scripts run in `bash` in _GNU/Linux_, so it expects usual commands to be available. These include `awk sed readlink wget tar git`, of which all are installed by default in Ubuntu Server 16.04

Also remember the [dependencies of SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)! (On Ubuntu/Debian 64 Bit: `sudo apt install lib32gcc1`)

Additional dependencies are:

* _tmux_, see https://tmux.github.io/ (Installed by default in Ubuntu Server 16.04)
* _inotifywait_, found in the `inotify-tools` package for Ubuntu, used by the server control to efficiently wait for file changes
* _unbuffer_, to make update and server output and logging smoother (try `sudo apt install expect`)

Of course, you require a Steam account with the game owned to create a CS:GO dedicated server. If you wish anybody to be able to connect to your server, get your Gameserver auth tokens [here](http://steamcommunity.com/dev/managegameservers) (for CS:GO, use appid 730).




## Configuration and Environment Variables

The main configuration file will be placed in `~/msm.d`. It will set up all the important environment variables.

* **ADMIN** - Name of the user that 'controls' the installation
* **INSTALL_DIR** - The directory of the base installation. In **ADMIN**'s control.
* **DEFAULT\_INSTANCE** - The instance to work on if no specific is selected

The server settings themselves are instance-specific and can be configured in `$INSTANCE_DIR/msm.d/cfg/server.conf`. Most importantly, you should check and set the `GSLT`, `IP` and `PORT` variables for every new instance.

**TO BE IMPLEMENTED:** Support for workshop maps, configuration and installation of addons, GOTV Settings have to be tested/refined.



## Installation

#### Steps for the server administrator

1. (Optional, if you want to use installation sharing) Create a separate _admin_ user (__NOT root__, usually called _steam_) that controls SteamCMD and the base installation. You can, of course, be your own admin.
2. Use `git clone https://github.com/dasisdormax/csgo-multiserver.git` to clone this repository to whatever place you like (preferably within the admin's home directory ~admin). Make sure this directory and all files in it are readable to all users who will use this script.
3. For easier invocation of the main script (just by typing `csgo-server` in your terminal), do one of the following:
    * `ln -s /home/admin/csgo-multiserver/csgo-server /usr/bin/csgo-server` (create a symlink)
    * add that place to your `$PATH` environment variable
4. As the admin user (__NOT root__), try `csgo-server setup`. This will guide you through creating the initial configuration.
5. Install updates or the server itself as the admin user with `csgo-server update` (possibly automated by cron)
 
#### Steps for the individual user

Note that individual servers are called _instances_. These share most of the files (like maps, textures, etc.) with the base installation, but can have their own configurations. The special command `@instance-name` selects the instance to run the future commands on. The command `@` without an instance name selects the base installation.

It is, though, not required to create a separate instance if you do not intend to run more than one server on the machine. You can simply run the base installation if you want to.

1. If this is the first time the script is used on the current account, type `csgo-server setup` and follow the instructions to import the configuration from the admin.
2. (If applicable) Create your own instance (a fork of the base installation) named _myinstance_ using `csgo-server @... create`.




## Usage, when fully set up

* `csgo-server @... ( start | stop | restart )` to start/stop/restart the given server instance. The server will run in the background in a separate tmux environment. Please note that the selected _admin_ can stop the server to perform updates without nasty effects.
* `csgo-server @... exec ...` to execute some command in the server's console
* `csgo-server @... console` to access the in-game console (= attach to the tmux environment) to manually enter commands. You can return to your original shell (detach) by typing CTRL-D, a frozen server can be killed using CTRL-K.
* `csgo-server usage` will display detailed usage information




## License

Apache License 2.0. I chose it because I specifically want to allow others to build services based on this script. However, I would still appreciate if improvements and fixes could make it back here.

__Be aware that the original csgo-server-launcher by crazy is licensed under the LGPLv3__, which still applies to earlier states of this repository. The license change has been marked with the tags __lgpl-until-here__ and __apache2-from-here__. Since the license change, crazy's code has been fully replaced by own code.
