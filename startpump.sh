#!/bin/bash

#sudo rm /var/log/pump-err.log
#sudo forever -a -e /var/log/pump-err.log start /usr/local/bin/pump -c /srv/pump.io/pump.io.json

rm -f /srv/pump.io/pump.log
sudo forever -l /srv/pump.io/pump.log start /srv/pump.io/bin/pump -c /srv/pump.io/pump.io.json
#sudo forever -l /dev/null start /srv/pump.io/bin/pump -c /srv/pump.io/pump.io.json

