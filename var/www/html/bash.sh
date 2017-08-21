#!/bin/bash
echo -e "Content-type: text/html\n"

TMPDIR="/tmp/pindanetZsYTpr5e9CXbcLCJCXNUxSFH1TdLYQqwrsa"
if [ ! -d "$TMPDIR" ]; then
  mkdir -p "$TMPDIR"
fi
FINGERPRINT=`echo ${HTTP_USER_AGENT}${REMOTE_ADDR} | md5sum | awk '{ print $1 }'`

# (internal) routine to store POST data
function cgi_get_POST_vars()
{
    # only handle POST requests here
    [ "$REQUEST_METHOD" != "POST" ] && return

    # save POST variables (only first time this is called)
    [ ! -z "$QUERY_STRING_POST" ] && return

    # skip empty content
    [ -z "$CONTENT_LENGTH" ] && return

    # check content type
    # FIXME: not sure if we could handle uploads with this..
    [ "${CONTENT_TYPE}" != "application/x-www-form-urlencoded" ] && \
        echo "bash.cgi warning: you should probably use MIME type "\
             "application/x-www-form-urlencoded!" 1>&2

    # convert multipart to urlencoded
    local handlemultipart=0 # enable to handle multipart/form-data (dangerous?)
    if [ "$handlemultipart" = "1" -a "${CONTENT_TYPE:0:19}" = "multipart/form-data" ]; then
        boundary=${CONTENT_TYPE:30}
        read -N $CONTENT_LENGTH RECEIVED_POST
        # FIXME: don't use awk, handle binary data (Content-Type: application/octet-stream)
        QUERY_STRING_POST=$(echo "$RECEIVED_POST" | awk -v b=$boundary 'BEGIN { RS=b"\r\n"; FS="\r\n"; ORS="&" }
           $1 ~ /^Content-Disposition/ {gsub(/Content-Disposition: form-data; name=/, "", $1); gsub("\"", "", $1); print $1"="$3 }')

    # take input string as is
    else
        read -N $CONTENT_LENGTH QUERY_STRING_POST
    fi

    return
}

# # (internal) routine to decode urlencoded strings
# function cgi_decodevar()
# {
#     [ $# -ne 1 ] && return
#     local v t h
#     # replace all + with whitespace and append %%
#     t="${1//+/ }%%"
#     while [ ${#t} -gt 0 -a "${t}" != "%" ]; do
#         v="${v}${t%%\%*}" # digest up to the first %
#         t="${t#*%}"       # remove digested part
#         # decode if there is anything to decode and if not at end of string
#         if [ ${#t} -gt 0 -a "${t}" != "%" ]; then
#             h=${t:0:2} # save first two chars
#             t="${t:2}" # remove these
#             v="${v}"`echo -e \\\\x${h}` # convert hex to special char
#         fi
#     done
#     # return decoded string
#     echo "${v}"
#     return
# }

# routine to get variables from http requests
# usage: cgi_getvars method varname1 [.. varnameN]
# method is either GET or POST or BOTH
# the magic varible name ALL gets everything
function cgi_getvars()
{
    [ $# -lt 2 ] && return
    local q p k v s
    # get query
    case $1 in
        GET)
            [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
            ;;
        POST)
            cgi_get_POST_vars
            [ ! -z "${QUERY_STRING_POST}" ] && q="${QUERY_STRING_POST}&"
            ;;
        BOTH)
            [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
            cgi_get_POST_vars
            [ ! -z "${QUERY_STRING_POST}" ] && q="${q}${QUERY_STRING_POST}&"
            ;;
    esac
    shift
    s=" $* "
    # parse the query data
    while [ ! -z "$q" ]; do
        p="${q%%&*}"  # get first part of query string
        k="${p%%=*}"  # get the key (variable name) from it
        v="${p#*=}"   # get the value from it
        q="${q#$p&*}" # strip first part from query string
        # decode and assign variable if requested
        [ "$1" = "ALL" -o "${s/ $k /}" != "$s" ] && \
#            export "$k"="`cgi_decodevar \"$v\"`"
            export "$k"="$v"
    done
    return
}

# register all GET and POST variables
cgi_getvars BOTH ALL

echo $json > ${TMPDIR}/${FINGERPRINT}_test.txt

case "$command" in
  genkey)
    get_wallpaper
    # oude keys opruimen
    numfiles=`ls ${TMPDIR} | wc -l`
    while [ $((numfiles)) -gt 10 ]; do
      oldest=`ls -t ${TMPDIR}/* | tail -1`
      rm $oldest
      numfiles=`ls ${TMPDIR} | wc -l`
    done
    
    openssl genrsa -out ${TMPDIR}/${FINGERPRINT}_priv.pem 1024
    openssl rsa -pubout -in ${TMPDIR}/${FINGERPRINT}_priv.pem -out ${TMPDIR}/${FINGERPRINT}_pub.pem
    cat ${TMPDIR}/${FINGERPRINT}_pub.pem | tail -n +2 | head -n -1
    rm ${TMPDIR}/${FINGERPRINT}_pub.pem
    exit
    ;;
#   genprivkey)
#     openssl genrsa -out ${TMPDIR}/${FINGERPRINT}_client_priv.pem 1024
#     openssl rsa -pubout -in ${TMPDIR}/${FINGERPRINT}_client_priv.pem -out ${TMPDIR}/${FINGERPRINT}_client_pub.pem
#     cat ${TMPDIR}/${FINGERPRINT}_client_priv.pem | tail -n +2 | head -n -1
#     rm ${TMPDIR}/${FINGERPRINT}_client_priv.pem
#     exit
#     ;;
  saveThermostat)
    echo $json > /var/www/html/data/thermostat.json
    exit
    ;;
#  loadThermostat)
#    cat /var/www/html/data/thermostat.json
#    exit
#    ;;
esac
pincode=`echo "$encpin" | openssl base64 -d | openssl rsautl -decrypt -inkey ${TMPDIR}/${FINGERPRINT}_priv.pem`

{ myCode=$(</dev/stdin); } << EOF
case "\$command" in
  system)
    html="<button onclick=\"location.reload();\">Vernieuwen</button>
        <button onclick=\"remoteCommand(event,'softap');\">WiFi AP</button>
        <button onclick=\"remoteCommand(event,'reboot');\">Herstart</button>
        <button onclick=\"remoteCommand(event,'halt');\">Uitschakelen</button>"
    echo \$html
    ;;
  softap)
    hostapd=`/bin/systemctl is-active hostapd.service`
    if [ \$hostapd == "inactive" ] || [ \$hostapd == "failed" ] || [ \$hostapd == "unknown" ]; then # start hostapd
      sudo /bin/systemctl start hostapd.service
      echo "WiFi AP actief"
    else
      sudo /bin/systemctl stop hostapd.service
      echo "WiFi AP uitgeschakeld"
    fi
    ;;
  reboot)
    sudo /sbin/shutdown -r now
    ;;
  halt)
    sudo /sbin/shutdown -h now
    ;;
  saveThermostat)
    echo $jason;;
  *)
    echo Error
esac
EOF

# encoderen
enc=`echo -n "$myCode" | openssl enc -e -aes-256-cbc -a -salt -pass pass:$pincode`

# Voorbeeld met pincode: 123
# Opgelet: $command wordt \$command

# enc='U2FsdGVkX1+X+zCKtg2sLMgNTkpaLtBdKN3IHGZhqyZT907t2d9FjuWxW75DwT6c
# HcwCnTN3jVCdHFRsjq+5fC90jL7gObjp0+k60h964wE3H0SUK0fC0+YA3Fh1wWg1
# v49ToUBIm6/qYGhnPRNBbfreCJnzMHvzm6i/ER3gw0QgkA4ss3AaSLY2MCE2oaR/
# iWjSXMlG8xuJqvCkdEU5glUSgQhbCZEGFKwFh136i3vpnUNPkS9aYXqUAnGHt1X+
# G4OtgheKQ4QH8tepHlwpA6UoEtJmMq7y6kE0ih0XN3S5OK0i7AoopZmuKsUlIDKz
# FbfcdIVxJPyLCIzy+bh6ERMrsJTknGTWvM/LtzXnRFin9geJK9uWz/OFDECUSswA
# ruSXYwdDkxiYZmBVOb9mWBoGxtgNo+mtRMTowMxQOL8rGQ37Mb6BZWkeTQh1LrFw
# 1pyyHtKp0cAWrZUX7UJUpn7+ckSluOBuOQjd33PO7YTYsr33TgetyGx6EY3BMw1H
# T/fEA5r1CT1ShrYxMKzpZAS8dQYdSgGu/9q6tUItKWGYLDZFPZh+yA4rxfFKelM6
# R6Mpvu9085n+xbHDXDBofA=='

# decoderen
dec=`echo "$enc" | openssl enc -d -aes-256-cbc -a -salt -pass pass:$pincode`

eval "$dec"
