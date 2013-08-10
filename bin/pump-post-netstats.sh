#!/bin/bash

server=pi.jrobb.org
port=443
user=pumpstats

note=$(echo "Network Stats:

")$(echo "<pre>

")$(vnstat)$(echo "

</pre>")

echo $note

cd /home/$(whoami)/srv/pump.io/bin
node pump-post-note -p -s $server -P $port -p -u $user -n "$note" >> /home/$(whoami)/srv/pump.io/log/pumpstats.log
