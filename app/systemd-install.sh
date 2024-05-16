#!/bin/bash
set -e

mkdir -p $DIR

cp $APP $DIR
cp $APP_KILLER $DIR

sudo -E envsubst '$DIR $APP $APP_KILLER $WHOAMI $NODE' < $SERVICE > /etc/systemd/system/$SERVICE
systemctl daemon-reload
systemctl start my-app
sleep 5
journalctl --unit=my-app -r --no-pager -n 30

# journalctl --unit=my-app -r
# systemctl status my-app
# systemctl enable my-app
# systemctl stop my-app
# sudo shutdown -h now

# mkdir -p ~/.config/systemd/user/
# sudo -E envsubst < $SERVICE > ~/.config/systemd/user/$SERVICE
# systemctl --user daemon-reload
# systemctl --user start my-app