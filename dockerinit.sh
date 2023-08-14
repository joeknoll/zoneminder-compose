#!/bin/bash

/usr/sbin/echo "date.timezone = '$PHP_TIMEZONE'" > /etc/php/conf.d/local.ini
# Clear up the repeating warning:
/usr/sbin/sed -e '/extension=zip/ s/^;*/;/' -i /etc/php/php.ini


/usr/sbin/echo "Starting fcgiwrap"
#/usr/sbin/su -s /bin/bash http -c "/usr/sbin/fcgiwrap -c 10 -s unix:/run/fcgiwrap/fcgiwrap.sock &"
/usr/sbin/su -s /bin/bash http -c "/usr/sbin/spawn-fcgi -s /run/fcgiwrap/fcgiwrap.sock -F 10 -U http -G http -- /usr/bin/fcgiwrap" || exit 1
/usr/sbin/echo "Starting php-fpm"
/usr/sbin/chown http:http /run/php-fpm
/usr/sbin/su -s /bin/bash http -c "/usr/sbin/php-fpm" || exit 1
/usr/sbin/echo "Starting nginx"


/usr/sbin/echo "Updating Zoneminder DB"
# Wait for the DB to spin up and respond
COUNT=0
while ! /usr/sbin/zmupdate.pl --nointeractive && [[ COUNT -lt 6 ]]; do
    sleep 5
    COUNT=$((COUNT+1))
done

/usr/sbin/zmupdate.pl --nointeractive -f || exit 1

/usr/sbin/echo "Starting Zoneminder"
/usr/sbin/su -s /bin/bash http -c "/usr/sbin/zmpkg.pl start" || exit 1

/usr/sbin/echo "ZM started on $(cat /run/zoneminder/zm.pid)"

exec /usr/sbin/nginx -g "daemon off;"

