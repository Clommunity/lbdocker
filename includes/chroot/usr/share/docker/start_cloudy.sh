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


# SSh
[ ! -f /etc/ssh/ssh_host_rsa_key ] && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
[ ! -f /etc/ssh/ssh_host_dsa_key ] && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''

getinconf-client install

/usr/sbin/sshd -D
