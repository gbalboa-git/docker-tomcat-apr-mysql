#!/bin/bash

set -e
cmd="$@"  
pass=$(${CATALINA_HOME}/bin/encrypt.sh -d ${DB_USR_PASS} | cut -d':' -f 2)
until mysql -h ${DB_HOST}  -u ${DB_USR_NAME}  --password="${pass}" -e 'Select 1'; do
  >&2 echo "DB is unavailable - sleeping"
  sleep 1
done  
>&2 echo "DB is up - Starting Tomcat"
exec $cmd