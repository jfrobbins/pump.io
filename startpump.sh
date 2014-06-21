#!/bin/bash

sudo forever start -al /srv/pump.io/logs/pump.log /srv/pump.io/bin/pump
