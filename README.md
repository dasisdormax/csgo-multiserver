# CS:GO *Multi* Server Manager

Launch and set up **Counter-Strike: Global Offensive** Dedicated Servers.



## About this project

This is a complete rewrite of [csgo-server-launcher](https://github.com/crazy-max/csgo-server-launcher) (which seemed to be primarily designed for rented root servers). Intention is to make server management easier in both shared server and LAN environments.

There is still A LOT to do!



### Currently working features

* SteamCMD and Game Installation



### Planned features

The emphasis is on **MULTI**
* **_MULTIPLE_ USERS**: An admin-client system for sharing the base installation. This can save bandwidth/storage
* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously. Supporting network bridges would be nice for the future.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server
    * e.g using `csgo-server start competitive`
    * More options should be controlled using environment variables, like **MAPS** (a mapcycle generator), **TEAM_T**, **TEAM_CT** (automatic team assignment, depends on plugins)

* Magic network features that let you start/stop a server on a remote machine and copy game/config files over 
* It should, though, still be easy to set it up just for one user
* Sourcemod plugin management for each instance (including downloading them), and enabling/disabling them based on configuration
* Support for Gameserver auth tokens and various other improvements



## Requirements

Of course, a Steam account is required to create a CS:GO dedicated server. Also get Gameserver auth tokens for CS:GO (App-ID 730) [here](http://steamcommunity.com/dev/managegameservers)

Required commands on the server:

Install the [dependencies for SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)! (On Ubuntu/Debian 64 Bit: `sudo apt-get install lib32gcc1`)

* _awk_, see https://en.wikipedia.org/wiki/Awk (should be default on linux servers)
* _tmux_, see https://tmux.github.io/
* _wget_, see https://en.wikipedia.org/wiki/Wget
* _tar_, see http://linuxcommand.org/man_pages/tar1.html

Recommended additions:

* _unbuffer_, to make update output and logging smoother (try `sudo apt-get install expect`)



## Installation

Executing `csgo-server` will present a simple setup if no configuration exists for that user. More details follow as soon as everything works



## Environment Variables

The main configuration file, by default, will be placed in `~/csgo-msm.conf`. It will set up all the important environment variables.

* **ADMIN** - Name of the user that 'controls' the installation
* **INSTALL_DIR** - The directory of the base installation. In **ADMIN**'s control.
* **DEFAULT_INSTANCE** - The default server instance
* **DEFAULT_MODE** - The default server gamemode

Other variables will be set up by configs within the game instance's directory

**LOTS OF STUFF IS MISSING**



## Usage - NEEDS TO BE REWORKED

For the console mode, press CTRL+D to detach (return to your normal console) without stopping the server.



## License

Apache License 2.0. This should give nobody worries when using my program and making modifications to it. I would, though, appreciate if code improvements could make it back here.

The original csgo-server-launcher by crazy is licensed as LGPLv3. At this point, no original code is being used anymore. See the branch [crazy](https://github.com/dasisdormax/csgo-multiserver/tree/crazy) for the last LGPL licensed state of this project.