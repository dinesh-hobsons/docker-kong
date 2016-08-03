#!/bin/sh

env | grep KONG

set -x
# Setting up the proper database
if [ -n "$DATABASE" ]; then
  echo -e '\ndatabase: "'$DATABASE'"' >> /etc/kong/kong.yml
else
    echo "DATABASE not set"
fi

if [ -n "$DATABASE_PORT" ]; then
    echo "Database Port: $DATABASE_PORT"
	sed -i.bak s/5432/$DATABASE_PORT/g /etc/kong/kong.yml
else
    echo "DATABASE_PORT not set"
fi

if [ -n "$DATABASE_PASSWORD" ]; then
	sed -i.bak s/kong-password/$DATABASE_PASSWORD/g /etc/kong/kong.yml
else
    echo "DATABASE_PASSWORD not set"
	sed -i.bak s/kong-password/kong/g /etc/kong/kong.yml
fi

if [ -n "$DATABASE_NAME" ]; then
    echo "Database Name: $DATABASE_NAME"
	sed -i.bak s/kongDB/$DATABASE_NAME/g /etc/kong/kong.yml
else
    echo "DATABASE_NAME not set"
	sed -i.bak s/kongDB/kong/g /etc/kong/kong.yml
fi

if [ -n "$DATABASE_HOST" ]; then
    echo "Database Host: $DATABASE_HOST"
	sed -i.bak s/kong-database/$DATABASE_HOST/g /etc/kong/kong.yml
else
    echo "DATABASE_HOST not set"
fi

if [ -n "$DATABASE_USER" ]; then
    echo "Database User: $DATABASE_USER"
	sed -i.bak s/kong-user/$DATABASE_USER/g /etc/kong/kong.yml
else
    echo "DATABASE_USER not set"
	sed -i.bak s/kong-user/kong/g /etc/kong/kong.yml
fi

