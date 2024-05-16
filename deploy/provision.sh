#!/bin/bash

set -e

# Initial configs
whoami
export DEBIAN_FRONTEND=noninteractive
cd /vagrant
sudo apt-get update

# Install Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 16.20.2
nvm use 16.20.2

# Start Systemd

export DIR=/home/vagrant
export APP=my-app.js
export APP_KILLER=my-app-killer.js
export SERVICE=my-app.service
export WHOAMI=$(whoami)
export NODE=$(which node)

cd ./app
mkdir -p $DIR

sudo -E ./systemd-install.sh