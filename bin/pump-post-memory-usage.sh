#!/bin/bash
# quick script to post stats regarding the redis backend
# for https://pump.jpope.org
# if anything blows up, don't blame jpope <jpope@jpope.org>
#
# this script uses 
# markdown (http://daringfireball.net/projects/markdown/)
# munin (http://munin-monitoring.org/)
# pump-post-note-titled (https://github.com/jpope777/pump.io/blob/pump.jpope.org/bin/pump-post-note-titled)
# pump-post-file (https://github.com/jpope777/pump.io/blob/pump.jpope.org/bin/pump-post-file)
#
# I have my munin instance web accessible but it requires http auth.

tmpfile=pumpstats
mdfile=pumpstats.md
tmpimage=/tmp/munin.png

pumpadd=pi.jrobb.org
pumpport=443
pumpuser=pumpstats
pumppath=/home/jon/srv/pump.io/bin
note=pump-post-note
image=pump-post-file

#munin=https://example.org/redis_used_memory-day.png
#httpuser=<username>
#httppass=<password>

touch $mdfile
touch $tmpfile

if [ -z "$1" ]; then
        #var is empty
        opt="-s"
else
	opt=$1
fi


case $opt in
    -s)
      dump=$(du -sh /srv/db/redis/redis-dump.rdb)
      redis1=$(redis-cli info|grep used_memory_human)
      redis2=$(redis-cli info|grep used_memory_peak_human)
      redis3=$(redis-cli info|grep db0)
#      users=$(redis-cli -n 0 keys "databank:index:user:profile.id:acct*"|grep $pumpadd|sort -r|uniq|wc -l)
      title=$(echo "Redis stats for $pumpadd")
      freememHdr=$(free -h | grep total)
      freemem=$(free -h | grep Mem)
      freeswap=$(free -h | grep Swap)
      uptime=$(uptime)
      diskspaceRoot=$(df -h|grep '/dev/root')
      diskspaceHome=$(df -h |grep home)
      {
      echo "**$(date)**"
      echo " "
      echo "**Redis Stats:**"
      echo " "
      echo "    $redis1"
      echo " "
      echo "    $redis2"
      echo " "
      echo "    $redis3"
      echo " "
      echo "    $dump"
      echo " "
      echo " "
      echo " "
      echo "**$ free -h**"
      echo " "
      echo "    $freememHdr"
      echo "    $freemem"
      echo "    $freeswap"
      echo " "
      echo " "
      echo "**$ df -h**"
      echo " "
      echo "    $diskspaceRoot"
      echo "    $diskspaceHome"
      echo " "
      echo " "
      echo "**$ uptime**"
      echo " "
      echo "    $uptime"
      echo " "


      }>> $mdfile
      markdown $mdfile > $tmpfile

      message=$(cat $tmpfile)
      node $pumppath/$note -p -u $pumpuser -s $pumpadd -P $pumpport -t "$title" -n "$message"

      rm $mdfile
      rm $tmpfile
      ;;
    -i)
      wget -q --http-user=$httpuser --http-password=$httppass $munin -O $tmpimage
      node $pumppath/$image -u $pumpuser -s $pumpadd -P $pumpport -f $tmpimage
#      node $pumppath/$image -p -u $pumpuser -s $pumpadd -P $pumpport -f $tmpimage
      rm $tmpimage
      ;;
esac

exit 0

