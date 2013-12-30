#!/bin/sh

apt-get update
apt-get install -y postgresql sqlite3 libsqlite3-dev build-essential

cd /vagrant && su -c ./provision-user.sh vagrant
