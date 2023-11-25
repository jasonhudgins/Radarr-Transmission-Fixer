(Docker Friendly) Radarr Transmission Fixer
======
A modified version of Cr4zyy's original script to work better in dockerized environments.  The principle difference is that it uses curl to send RPC/API commands to transmission which removes the dependency on having the transmission-remote CLI installed.  It also logs to STDERR instead of log file so you can view the output using docker logs.

## Setup

* Change the USER:PASSWD to your USERNAME and PASSWORD for your Transmission. If you don't have a password you can remove the '-n USER:PASSWD'
* Run this script as a "custom script" from Radarr's "Settings > Connect > Connections" option. Set it to function 'On Download/Upgrade' put in the path to the script and save.
* Make sure the script is executable by the Radarr user
* Ideally meant to run with Radarr copying files, not hardlinking
* BASH script
* Optionally refresh season within Radarr to update not captured file moves
* Optionally empty plex trash in Movie library, use plex_library_key.sh to find the library number


