#!/bin/bash
DOWNLOADBUTTONS=$(wget -qO - --post-data 'view=paged&min_resolution=1920x1080&resolution_equals=%3D&sort_search=newest' https://wall.alphacoders.com/search.php?search=landscape\&page=$(((RANDOM % 50) + 1)) | awk '/download-button\"/{print}')
BUTTONCOUNT=$(echo "$DOWNLOADBUTTONS" | wc -l)
readarray -t BUTTONSARRAY <<<"$DOWNLOADBUTTONS"
BUTTON=$(echo ${BUTTONSARRAY[((RANDOM %BUTTONCOUNT))]})
OIFS="$IFS"
IFS="\""
read -a BUTTONARRAY <<<"$BUTTON"
IFS="$OIFS"
echo "https://initiate.alphacoders.com/download/wallpaper/${BUTTONARRAY[5]}/${BUTTONARRAY[9]}/${BUTTONARRAY[7]}/${BUTTONARRAY[11]}"
