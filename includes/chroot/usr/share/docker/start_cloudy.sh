#!/bin/bash
# Start

mkdir -p /var/run/sshd

# Apache :
chown -R www-data:www-data /var/www
chown -R www-data:www-data /var/lock/apache2
service apache2 start

# cDistro
service cdistro start

# Cron
service cron start

# service mysql start

service tinc start

# avahi necessita el DBUS
service dbus start
service avahi-daemon start


# SSh restart 
# Generate new keys
[ ! -f /etc/ssh/ssh_host_dsa_key ] && dpkg-reconfigure openssh-server
 
getinconf-client install

ip addr show eth0

/usr/sbin/sshd -D
