#!/bin/sh

apt-get update
apt-get install -y postgresql sqlite3 libsqlite3-dev build-essential libxml2-dev libexpat1-dev

cd /vagrant && su -c ./provision-user.sh vagrant
