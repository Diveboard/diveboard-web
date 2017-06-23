#!/bin/sh
##
## Daily backup script
## inspired from http://blog.interlinked.org/tutorials/rsync_time_machine.html
##
##
##

date=`date "+%Y-%m-%dT%H_%M_%S"`
start_time=$(date +%s)
echo "Daily backup started on $(date)"

mkdir -p /home/backup/daily
rm -rf /home/backup/daily/*
mkdir -p /home/backup/daily/db
chmod 777 /home/backup/daily/db

ionice -c 3 mysqldump --lock-tables=false  --tab=/home/backup/daily/db --user=dbuser --password='VZfs591bnw32d' diveboard


HOME=/home/backup/daily/

diveboard_current=`readlink -f /var/www/alpha.diveboard/current`
nginx_current=`readlink -f /opt/nginx`

#embed is a symlink to . it breaks my balls so we exclude it
ssh dbackup@vm.diveboard.com mkdir -p daily/incomplete_back-$date
ionice -c 3 nice -n 10 rsync -azprqog \
  --delete \
  --delete-excluded \
  --link-dest=../current \
  /etc \
  /home/backup/daily \
  /var/www/alpha.diveboard/shared/public \
  /var/www/alpha.diveboard/shared/tmp \
  /var/www/alpha.diveboard/shared/uploads \
  /var/www/alpha.diveboard/shared/system \
  $diveboard_current \
  $nginx_current \
  -e ssh dbackup@vm.diveboard.com:daily/incomplete_back-$date \
  && ssh dbackup@vm.diveboard.com \
  "mv daily/incomplete_back-$date daily/back-$date \
  && rm -f daily/current \
  && ln -s back-$date daily/current"

rc=$? #saves the result of the operation

finish_time=$(date +%s)

if [ $rc != 0 ] ; then
  /usr/local/bin/nma.pl -apikey=eb30e9a57e13ba81965f4085b4b4e4416b0312c8c4578999 -application=Diveboard -event="Backup failed" -notification="Daily backup failed in $(( $((finish_time - start_time)) / 60)) mins error $rc" -priority=2
  echo "Daily backup failed in $(( $((finish_time - start_time)) / 60)) mins error $rc"
else
  /usr/local/bin/nma.pl -apikey=eb30e9a57e13ba81965f4085b4b4e4416b0312c8c4578999 -application=Diveboard -event="Backup succeeded" -notification="Daily backup completed successfully in $(( $((finish_time - start_time)) / 60)) mins"
  echo "backup finished in $(( $((finish_time - start_time)) / 60)) mins"
fi

