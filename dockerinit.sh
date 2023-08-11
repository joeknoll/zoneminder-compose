#!/bin/bash

/usr/sbin/echo "date.timezone = '$PHP_TIMEZONE'" > /etc/php/conf.d/local.ini
# Clear up the repeating warning:
/usr/sbin/sed -e '/extension=zip/ s/^;*/;/' -i /etc/php/php.ini

/usr/sbin/php-fpm
/usr/sbin/zmpkg.pl start
/usr/sbin/su -s /bin/bash http -c "/usr/sbin/fcgiwrap -f -s unix:/run/fcgiwrap/fcgiwrap.sock &"
exec /usr/sbin/nginx -g "daemon off;"

