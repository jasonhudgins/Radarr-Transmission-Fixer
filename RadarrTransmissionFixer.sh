#!/bin/bash

# A simple script for Radarr to run on download completion

# VARIABLES
TRANSMISSION_URL="http://your_transmission_daemon:port/transmission/rpc" # Change this to your Transmission RPC URL
TRANSMISSION_USER="user" # Transmission username if authentication is enabled
TRANSMISSION_PASSWORD="password" # Transmission password if authentication is enabled

ENABLE_RADARR_REFRESH=0 # set 1 if you want radarr to refresh the movie
ENABLE_PLEX_TRASH=0  # set 1 if you want the script to clear plex trash

PLEXTOKEN="PLEX TOKEN" # add plex token if ENABLE_PLEX_TRASH=1
LIBRARY="LIBRARY ID"  # library id of plex
APIKEY="RADARR API KEY" # Radarr API Key

# IPS AND PORTS change as needed
PLEX_IP="127.0.0.1"
PLEX_PORT="32400"
RADARR_IP="127.0.0.1"
RADARR_PORT="7878"

# DONT CHANGE BELOW THIS LINE

# date and time
DT=$(date '+%Y-%m-%d %H:%M:%S')

printferr() { echo "$@" >&2; }

# Torrent details
TORRENT_ID="${radarr_download_id}"
printferr "TORRENT_ID: $TORRENT_ID"

# Torrent title
TORRENT_TITLE="${radarr_moviefile_scenename}"

# relative path of the target directory
SPATH="${radarr_moviefile_relativepath}"

# this is the ultimate destination of the file
STORED_FILE="${radarr_moviefile_path}"
printferr "STORED_FILE: $STORED_FILE"

# this is the destination of the file as it was downloaded
ORIGIN_FILE="${radarr_sourcepath}"
printferr "ORIGIN_FILE: $ORIGIN_FILE"

# Use dirname to get the directory path
SOURCEDIR=$(dirname "$radarr_sourcepath")
printferr "SOURCEDIR: $SOURCEDIR"

# this is torrent id within transmission
MOVIE_ID="${radarr_movie_id}"
printferr "MOVIE_ID: $MOVIE_ID"

# movie title
TITLE="${radarr_movie_title}"
printferr "TITLE: $TITLE"


# define printferr routine
printferr() { echo "$@" >&2; }

# announce start
printferr "Processing $TITLE | ${radarr_movie_year}"

# make sure the file exists
if [ -e "$ORIGIN_FILE" ]; then
    printferr "$DT | INFO  | Processing new download of: $TITLE"
    printferr "$DT | INFO  | Torrent ID: $TORRENT_ID | Torrent Name: $TORRENT_NAME"

    printferr "Processing new download: $TITLE"

    # Step 1, copy original to the final destination and rename
    printferr "Copying $ORIGIN_FILE to $STORED_FILE"
    # Ensure the destination directory exists
    mkdir -p "$(dirname "$STORED_FILE")"
    # Copy the file
    cp "$ORIGIN_FILE" "$STORED_FILE"

    # Step 2, remove the torrent from Transmission
    # Get the session ID
    SESSION_ID=$(curl -si $TRANSMISSION_URL | grep -oP 'X-Transmission-Session-Id: \K.*')

    # Remove the torrent from Transmission using the RPC API
    REMOVE_RESPONSE=$(curl -s -u $TRANSMISSION_USER:$TRANSMISSION_PASSWORD --header "X-Transmission-Session-Id: $SESSION_ID" \
                      --data '{"method":"torrent-remove","arguments":{"ids":['"$TORRENT_ID"'],"delete-local-data":true}}' \
                      $TRANSMISSION_URL)

    # Check for successful removal
    if [[ $REMOVE_RESPONSE == *"success"* ]]; then
        printferr "Torrent ID: $TORRENT_ID removed from Transmission"
    else
        printferr "Failed to remove Torrent ID: $TORRENT_ID from Transmission. Response: $REMOVE_RESPONSE"
    fi
else
    printferr "Downloaded file not found: $ORIGIN_FILE"
fi

# Plex trash cleanup
if [ $ENABLE_PLEX_TRASH -eq 1 ]; then
    printferr "Telling Plex to clean up trash"
    curl -s -X PUT -H "X-Plex-Token: $PLEXTOKEN" http://$PLEX_IP:$PLEX_PORT/library/sections/$LIBRARY/emptyTrash
fi

# Radarr movie rescan
if [ $ENABLE_RADARR_REFRESH -eq 1 ]; then
    printferr "Telling Radarr to rescan movie files for ID: $MOVIE_ID"
    curl -s -H "Content-Type: application/json" -H "X-Api-Key: $APIKEY" -d "{\"name\":\"RefreshMovie\",\"movieIds\":[$MOVIE_ID]}" http://$RADARR_IP:$RADARR_PORT/api/v3/command > /dev/null
fi

printferr "Script processing completed."
