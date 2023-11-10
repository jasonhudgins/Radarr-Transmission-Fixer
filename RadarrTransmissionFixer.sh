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

# Event type
EVENTTYPE="${radarr_eventtype}"

# Torrent details
TORRENT_ID="${radarr_download_id}"
STORED_FILE="${radarr_moviefile_path}"
ORIGIN_FILE="${radarr_moviefile_sourcepath}"
SOURCEDIR="${radarr_moviefile_sourcefolder}"
MOVIE_ID="${radarr_movie_id}"

printferr() { echo "$@" >&2; }

if [[ "$EVENTTYPE" == "Test" ]]; then
    printferr "Connection Test Successful"
    exit 0
else
    printferr '%s | INFO  | Radarr Event - %s\n' "$DT" "$EVENTTYPE" 
    printferr "Processing $TITLE | ${radarr_movie_year}"
fi

# Loop over each environment variable
for var in $(compgen -e); do
    # Print the environment variable and its value
    printferr "$var=${!var}"
done

# this is all we are doing for now, we want to verify / test the existence
# all our environment variables
exit(0)


printferr "Processing event type: $EVENTTYPE"

if [ -e "$STORED_FILE" ]; then
    printferr "$DT | INFO  | Processing new download of: $TITLE"
    printferr "$DT | INFO  | Torrent ID: $TORRENT_ID | Torrent Name: $TORRENT_NAME"
    printferr "$DT | INFO  | Movie file detected as: $SPATH"

    printferr "Processing new download: ${radarr_movie_title}"

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

    # Delete the original file
    if [ -e "$ORIGIN_FILE" ]; then
        rm -f "$ORIGIN_FILE"
        printferr "Deleted original file: $ORIGIN_FILE"
        
        # Check and remove source directory if empty
        if [ "$(ls -A "$SOURCEDIR")" ]; then
            printferr "Source directory $SOURCEDIR is not empty. Skipping removal."
        else
            rmdir "$SOURCEDIR" && printferr "Removed empty source directory: $SOURCEDIR"
        fi
    else
        printferr "Original file not found: $ORIGIN_FILE"
    fi
else
    printferr "Stored file not found: $STORED_FILE"
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
