#!/bin/bash
# 
# Apply this configuration to the sympa.conf file.
# The script makes a backup of the sympa.conf to sympa.conf.tpl if
# sympa.conf.tpl does't exists and replaces the ${VARIABLES} using the CONF
# variables. 
# Feel free to improve
#
CONF=(
  DOMAIN=localhost
  LISTMASTER=root@localhost.localdomain
  WWSYMPA_URL=http://127.0.0.1:8008/lists
  COOKIE=GenerateSring
  DB_HOST=sympa_db
  DB_PASSWD=sympa
  HTTP_HOST=http://127.0.0.1:8008/
  SOAP_URL=http://127.0.0.1:8008/sympasoap
  COOKIE_DOMAIN=127.0.0.1
)

function applyConf() {
  if [ ! -f sympa.conf.tpl ] ; then
    cp sympa.conf sympa.conf.tpl
  else 
    cp sympa.conf.tpl sympa.conf
  fi
  for c in ${CONF[*]} ; do
    name=$(echo $c |cut -d "=" -f1)
    value=$(echo $c |cut -d "=" -f2|sed -e "s/\//\\\\\//g")
    sed -e "s/\${$name}/$value/" sympa.conf  -i
  done
}

applyConf
