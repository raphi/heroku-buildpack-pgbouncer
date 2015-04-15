#!/usr/bin/env bash

echo "$TWEMPROXY_PEM" > /app/vendor/stunnel/twemproxy.pem
REDIS_URLS=${TWEMPROXY_URLS:-REDIS_DB_URL}
n=0

# Routing Redis commands to external Redis instances using Stunnel
for REDIS_URL in $REDIS_URLS
do
  eval REDIS_URL_VALUE=\$$REDIS_URL

  REDIS=$(echo $REDIS_URL_VALUE | perl -lne 'print "$1 $2 $3" if /^redis:\/\/(.*?):(.*?)\/(.*?)?$/')
  REDIS_URI=( $REDIS )
  REDIS_HOST=${REDIS_URI[0]}
  REDIS_PORT=${REDIS_URI[1]}
  REDIS_DB=${REDIS_URI[2]}

  echo "Setting ${REDIS_URL}_TWEMPROXY config var"
  export ${REDIS_URL}_TWEMPROXY=redis://127.0.0.1:999${n}/

  cat >> /app/vendor/stunnel/stunnel-pgbouncer.conf << EOFEOF
[$REDIS_URL]
cert = /app/vendor/stunnel/twemproxy.pem
client = yes
accept = 999${n}
connect = $REDIS_HOST:$REDIS_PORT
EOFEOF

  let "n += 1"
done
