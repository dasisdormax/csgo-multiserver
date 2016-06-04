# CS:GO *Multi* Server Manager

Launch and set up **Counter-Strike: Global Offensive** Dedicated Servers.




## About this project

This is a complete rewrite of [csgo-server-launcher](https://github.com/crazy-max/csgo-server-launcher) (which seemed to be primarily designed for rented root servers). Intention is to make server management easier in both shared server and LAN environments.

There is still A LOT to do!




## Currently working features

* SteamCMD and Game Installation, checking for and performing updates
* CS:GO Server instance creation
* Instance configuration using `$INSTANCE_DIR/msm.d/server.conf` config file.
	* In most cases, variables set using the command line are more important than configuration file settings.
	* Select the mode with the **MODE** variable, custom modes can be configured in `$INSTANCE_DIR/msm.d/modes/$MODE.conf`
* Starting a server basically works! Yay! 




## Planned features

The emphasis is on **MULTI**
* **_MULTIPLE_ USERS**: An admin-client system for sharing the base installation. This can save bandwidth/storage
* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously. Supporting network bridges would be nice for the future.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server

* More options should be controlled using environment variables, like **MAPS** (a mapcycle generator), **TEAM\_T**, **TEAM\_CT** (automatic team assignment, depends on plugins)
* Magic network features that let you start/stop a server on a remote machine and copy game/config files over (far future, you can use ssh and rsync anyway)
* It should, though, still be easy to set it up just for one user
* Sourcemod plugin management for each instance (including downloading them), and enabling/disabling them based on configuration
* various improvements and all that stuff




## Requirements

These scripts run in `bash` in _GNU/Linux_, so it expects usual commands to be available. These include `awk sed readlink wget tar git`, of which all are installed by default in Ubuntu Server 16.04

Also remember the [dependencies of SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)! (On Ubuntu/Debian 64 Bit: `sudo apt install lib32gcc1`)

Additional dependencies are:

* _tmux_, see https://tmux.github.io/ (Installed by default in Ubuntu Server 16.04)
* _inotifywait_, found in the `inotify-tools` package for Ubuntu, used by the server control to efficiently wait for file changes 

Highly recommended additions:

* _unbuffer_, to make update and server output and logging smoother (try `sudo apt install expect`)

Of course, you require a Steam account with the game owned to create a CS:GO dedicated server. If you wish anybody to be able to connect to your server, get your Gameserver auth tokens [here](http://steamcommunity.com/dev/managegameservers) (for CS:GO, use appid 730).




## Configuration and Environment Variables

The main configuration file, by default, will be placed in `~/csgo-msm.conf`. It will set up all the important environment variables.

* **ADMIN** - Name of the user that 'controls' the installation
* **INSTALL_DIR** - The directory of the base installation. In **ADMIN**'s control.
* **DEFAULT\_INSTANCE** - The default server instance
* **DEFAULT\_MODE** - The default server gamemode

Other variables will be set up by configs within the game instance's directory

**LOTS OF STUFF IS MISSING**



## Installation

#### Steps for the server administrator

1. (Optional, if you want to use installation sharing) Create a separate _admin_ user (__NOT root__, usually called _steam_) that controls SteamCMD and the base installation. You can, of course, be your own admin.
2. Use `git clone https://github.com/dasisdormax/csgo-multiserver.git` to clone this repository to whatever place you like (preferably within the admin's home directory ~admin). Make sure this directory and all files in it are readable to all users who will use this script.
3. For easier invocation of the main script (just by typing `csgo-server` in your terminal), do one of the following:
    * `ln -s /home/admin/csgo-multiserver/csgo-server /usr/bin/csgo-server` (create a symlink)
    * add that place to your `$PATH` environment variable
4. As the admin user (__NOT root__), try `csgo-server admin-install`. This will guide you through creating the initial configuration, downloading SteamCMD, and optionally installing and updating the base game server installation.
5. Manage regularly and install updates as the admin user, with `csgo-server update` (possibly automated by cron)
 
#### Steps for the individual user

Note that individual servers are called _instances_. These share most of the files (like maps, textures, etc.) with the base installation, but can have their own configurations.

It is, though, not required to create a separate instance if you do not intend to run more than one server on the machine. If you omit the instance parameter `@instance-name`, the base installation will be selected by default.

1. If this is the first time the script is used on the current account, type `csgo-server` and follow the instructions to import the configuration from the admin.
2. (If applicable) Create your own instance (a fork of the base installation) named _myinstance_ using `csgo-server @myinstance create`.
3. Manage mods/addons using `csgo-server @myinstance manage`




## Usage, when fully set up

* `csgo-server @instance-name ( start | stop | restart )` to start/stop/restart the given server instance respectively. The server will run in the background in a separate tmux environment. Please note that the selected _admin_ can stop the server to perform updates without nasty effects.
* `csgo-server @instance-name console` to access the in-game console (= attach to the tmux environment) to manually enter commands. You can return to your original shell (detach) by typing CTRL-D, a frozen server can be killed using CTRL-K.
* `csgo-server usage` will display detailed usage information
* `csgo-server info` for information about copyright and license.

Other commands are sufficiently explained in the installation section above, I suppose.




## License

Apache License 2.0. I chose it because I specifically want to allow others to build services upon this script. However, I would still appreciate if improvements and fixes could make it back here.

__Be aware that this only applies since MARCH 29, 2016__ (to be exact, since commit [20645aa](https://github.com/dasisdormax/csgo-multiserver/commit/20645aa13a654226fc08312411f6462bdb9c877f))

For earlier states of this repository (or up to the top of branch [crazy](https://github.com/dasisdormax/csgo-multiserver/tree/crazy)), the LGPLv3 still applies. The LGPLv3 was used by the original csgo-server-launcher by crazy. At this point, no original code is being used anymore. 
