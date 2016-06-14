#!/bin/sh

env | grep KONG

set -x
# Setting up the proper database
if [ -n "$DATABASE" ]; then
  echo -e '\ndatabase: "'$DATABASE'"' >> /etc/kong/kong.yml
fi

if [ -n "$KONG_DATABASE_PORT_5432_TCP_PORT" ]; then
	sed -i.bak s/5432/$KONG_DATABASE_PORT_5432_TCP_PORT/g /etc/kong/kong.yml
fi

if [ -n "$KONG_DATABASE_PASSWORD" ]; then
	sed -i.bak s/kong-password/$KONG_DATABASE_PASSWORD/g /etc/kong/kong.yml
fi

